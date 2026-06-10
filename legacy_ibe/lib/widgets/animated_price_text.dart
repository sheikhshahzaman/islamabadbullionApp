import "dart:async";
import "dart:math";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../providers/animated_price_control_provider.dart";

/// AnimatedPriceText
/// - Smoothly animates value changes
/// - Keeps numbers LTR even in Urdu/RTL UI
/// - Randomly changes only the last 2 decimals on interval
/// - Green flash when last-2-decimals go up
/// - Red flash when last-2-decimals go down
/// - Admin can remotely turn animation ON/OFF without touching call-sites
class AnimatedPriceText extends StatefulWidget {
  final double value;
  final String currencyPrefix;
  final TextStyle? style;

  final Duration changeAnim;
  final int decimals;

  final bool pulseDecimals;
  final Duration decimalPulse;

  final bool fluctuateLastTwoDecimals;
  final Duration fluctuateInterval;

  final bool flashOnFluctuation;
  final Duration flashHold;
  final Duration flashAnim;

  final Color upFlashColor;
  final Color downFlashColor;

  final EdgeInsetsGeometry backgroundPadding;
  final BorderRadiusGeometry backgroundRadius;

  /// Local hard switch. Remote admin switch is applied on top of this.
  final bool enabled;

  const AnimatedPriceText({
    super.key,
    required this.value,
    required this.currencyPrefix,
    this.style,
    this.changeAnim = const Duration(milliseconds: 900),
    this.decimals = 2,
    this.pulseDecimals = true,
    this.decimalPulse = const Duration(milliseconds: 1200),
    this.fluctuateLastTwoDecimals = true,
    this.fluctuateInterval = const Duration(seconds: 2),
    this.flashOnFluctuation = true,
    this.flashHold = const Duration(milliseconds: 900),
    this.flashAnim = const Duration(milliseconds: 220),
    this.upFlashColor = const Color(0xff50C878),
    this.downFlashColor = const Color(0xffFF3131),
    this.backgroundPadding =
    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    this.backgroundRadius = const BorderRadius.all(Radius.circular(8)),
    this.enabled = true,
  });

  @override
  State<AnimatedPriceText> createState() => _AnimatedPriceTextState();
}

class _AnimatedPriceTextState extends State<AnimatedPriceText>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  final AnimatedPriceControlProvider _control =
      AnimatedPriceControlProvider.instance;

  late final AnimationController _pulse;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  Timer? _tickTimer;
  Timer? _flashResetTimer;

  late double _tweenBegin;
  int _lastTwo = 0;
  Color? _flashBg;

  bool _remoteEnabled = true;

  /// Freeze only the animated decimal effect when remote animation is turned off.
  String? _frozenDecPart;

  bool get _effectiveEnabled => widget.enabled && _remoteEnabled;
  bool get _canPulse => _effectiveEnabled && widget.pulseDecimals;
  bool get _canFluctuate =>
      _effectiveEnabled &&
          widget.fluctuateLastTwoDecimals &&
          widget.decimals >= 2;

  @override
  void initState() {
    super.initState();

    _remoteEnabled = _control.enabled;
    _control.ensureStarted();
    _control.addListener(_onRemoteControlChanged);

    _tweenBegin = widget.value;
    _lastTwo = _initialLastTwo(widget.value);

    _pulse = AnimationController(
      vsync: this,
      duration: widget.decimalPulse,
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.70).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    if (_canPulse) {
      _pulse.repeat(reverse: true);
    }

    _configureTickTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldEffectiveEnabled = oldWidget.enabled && _remoteEnabled;
    final newEffectiveEnabled = widget.enabled && _remoteEnabled;

    if (oldWidget.value != widget.value) {
      _tweenBegin = oldWidget.value;
      _lastTwo = _initialLastTwo(widget.value);

      // When animation is OFF, show new real value instantly, but keep the
      // frozen display-only decimals until animation is turned back on.
      if (newEffectiveEnabled) {
        _frozenDecPart = null;
      }
    }

    if (oldEffectiveEnabled != newEffectiveEnabled) {
      _handleEffectiveEnabledChange(
        oldEnabled: oldEffectiveEnabled,
        newEnabled: newEffectiveEnabled,
      );
    }

    if (oldWidget.decimalPulse != widget.decimalPulse) {
      _pulse.duration = widget.decimalPulse;
      if (_canPulse) {
        _pulse
          ..reset()
          ..repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    } else if (oldWidget.pulseDecimals != widget.pulseDecimals) {
      if (_canPulse) {
        _pulse
          ..reset()
          ..repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    }

    final tickSettingsChanged =
        oldWidget.fluctuateLastTwoDecimals != widget.fluctuateLastTwoDecimals ||
            oldWidget.fluctuateInterval != widget.fluctuateInterval;

    if (tickSettingsChanged) {
      _configureTickTimer();
    }
  }

  void _onRemoteControlChanged() {
    if (!mounted) return;

    final oldEnabled = _effectiveEnabled;
    final nextRemoteEnabled = _control.enabled;
    final newEnabled = widget.enabled && nextRemoteEnabled;

    if (_remoteEnabled == nextRemoteEnabled) return;

    setState(() {
      _remoteEnabled = nextRemoteEnabled;
      _handleEffectiveEnabledChange(
        oldEnabled: oldEnabled,
        newEnabled: newEnabled,
      );
    });
  }

  void _handleEffectiveEnabledChange({
    required bool oldEnabled,
    required bool newEnabled,
  }) {
    if (oldEnabled == newEnabled) return;

    if (oldEnabled && !newEnabled) {
      _tickTimer?.cancel();
      _tickTimer = null;

      _flashResetTimer?.cancel();
      _flashResetTimer = null;
      _flashBg = null;

      // Freeze the currently displayed decimal effect.
      _frozenDecPart = _displayDecimalsFor(
        widget.value,
        fluctuate: widget.fluctuateLastTwoDecimals && widget.decimals >= 2,
      );

      _pulse.stop();
    } else if (!oldEnabled && newEnabled) {
      _frozenDecPart = null;
      _lastTwo = _initialLastTwo(widget.value);

      if (widget.pulseDecimals) {
        _pulse
          ..reset()
          ..repeat(reverse: true);
      }

      _configureTickTimer();
    }
  }

  void _configureTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;

    if (!_canFluctuate) return;

    _tickTimer = Timer.periodic(widget.fluctuateInterval, (_) {
      if (!mounted) return;

      final old = _lastTwo;
      int next = old;

      for (int i = 0; i < 6 && next == old; i++) {
        next = _rng.nextInt(100);
      }

      final wentUp = next > old;
      final wentDown = next < old;

      setState(() {
        _lastTwo = next;

        if (widget.flashOnFluctuation) {
          if (wentUp) {
            _flashBg = widget.upFlashColor;
          } else if (wentDown) {
            _flashBg = widget.downFlashColor;
          } else {
            _flashBg = null;
          }
        }
      });

      if (widget.flashOnFluctuation) {
        _flashResetTimer?.cancel();
        _flashResetTimer = Timer(widget.flashHold, () {
          if (!mounted) return;
          setState(() => _flashBg = null);
        });
      }
    });
  }

  int _initialLastTwo(double v) {
    final abs = v.abs();
    final scaled = (abs * 100.0).round();
    return scaled % 100;
  }

  String _format(double v) {
    final fmt = NumberFormat("#,##0.${"0" * widget.decimals}", "en_US");
    return fmt.format(v);
  }

  String _rawDecimalsFor(double v) {
    final str = _format(v);
    final parts = str.split(".");
    return (parts.length > 1 ? parts[1] : "")
        .padRight(widget.decimals, "0")
        .substring(0, widget.decimals);
  }

  String _applyLastTwoFluctuation(String decPart) {
    if (widget.decimals < 2) return decPart;

    final fixed =
    decPart.padRight(widget.decimals, "0").substring(0, widget.decimals);
    final lastTwo = _lastTwo.toString().padLeft(2, "0");

    if (widget.decimals == 2) return lastTwo;

    final lead = fixed.substring(0, widget.decimals - 2);
    return "$lead$lastTwo";
  }

  String _displayDecimalsFor(double v, {required bool fluctuate}) {
    final rawDec = _rawDecimalsFor(v);
    if (!fluctuate) return rawDec;
    return _applyLastTwoFluctuation(rawDec);
  }

  TextStyle _withFallbackWhite(TextStyle s) =>
      s.copyWith(color: s.color ?? Colors.white);

  Widget _buildPrice(double v) {
    final base =
    _withFallbackWhite(widget.style ?? Theme.of(context).textTheme.titleMedium!);
    final curStyle = base.copyWith(fontWeight: FontWeight.w600);
    final numStyle = base.copyWith(fontWeight: FontWeight.w800);

    final str = _format(v);
    final parts = str.split(".");
    final intPart = parts.isNotEmpty ? parts[0] : str;

    final decPart = _frozenDecPart ??
        _displayDecimalsFor(
          v,
          fluctuate: _canFluctuate,
        );

    Widget decimalsWidget = Text(decPart, style: numStyle);

    if (_canPulse && widget.decimals > 0) {
      decimalsWidget = SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: decimalsWidget,
        ),
      );
    }

    return AnimatedContainer(
      duration: _effectiveEnabled ? widget.flashAnim : Duration.zero,
      curve: Curves.easeOut,
      padding: widget.backgroundPadding,
      decoration: BoxDecoration(
        color: _effectiveEnabled ? (_flashBg ?? Colors.transparent) : Colors.transparent,
        borderRadius: widget.backgroundRadius,
      ),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("${widget.currencyPrefix} ", style: curStyle),
            Text(intPart, style: numStyle),
            if (widget.decimals > 0) ...[
              Text(".", style: numStyle),
              decimalsWidget,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_effectiveEnabled) {
      return _buildPrice(widget.value);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _tweenBegin, end: widget.value),
      duration: widget.changeAnim,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return _buildPrice(v);
      },
    );
  }

  @override
  void dispose() {
    _control.removeListener(_onRemoteControlChanged);
    _tickTimer?.cancel();
    _flashResetTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }
}