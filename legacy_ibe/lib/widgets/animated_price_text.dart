import "dart:async";
import "dart:math";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../providers/animated_price_control_provider.dart";

/// Which digits are allowed to move for the cosmetic ticking effect.
enum PriceFluctuation {
  /// Nothing moves. The exact value is shown.
  none,

  /// Only the digits after the decimal point move. Used for international
  /// spot, where the dollar figure stays locked.
  decimals,

  /// Only the two digits BEFORE the decimal point move. Everything above them
  /// stays exactly as the admin set it, so Rs 456,999 ticks within
  /// Rs 456,900-456,999 and never misreads at a glance.
  ///
  /// Applied to the admin-managed gold and silver rate board.
  lastTwoDigits,
}


/// Value below which moving the last two digits would distort the number too
/// much (they would be a large share of it), so those tick the decimals instead.
const double kLastTwoDigitsFloor = 1000;

/// Resolves the mode actually used for [value].
PriceFluctuation effectivePriceFluctuation(
  double value,
  PriceFluctuation requested,
) {
  if (requested != PriceFluctuation.lastTwoDigits) return requested;

  return value.abs() >= kLastTwoDigitsFloor
      ? PriceFluctuation.lastTwoDigits
      : PriceFluctuation.decimals;
}

/// Applies the cosmetic tick, returning the number to draw.
///
/// Everything above the moving digits is taken straight from the real value, so
/// the price never misreads at a glance and the admin figure stays the anchor.
/// This is display only: real prices are never touched by it.
double applyPriceFluctuation({
  required double value,
  required PriceFluctuation mode,
  required int lastTwo,
}) {
  final resolved = effectivePriceFluctuation(value, mode);
  if (resolved == PriceFluctuation.none) return value;

  final negative = value.isNegative;
  final abs = value.abs();

  final shown = switch (resolved) {
    // Lock the integer part, move the decimals.
    PriceFluctuation.decimals => abs.floorToDouble() + lastTwo / 100.0,

    // Lock everything above the last two digits, move those.
    PriceFluctuation.lastTwoDigits => (abs / 100).floorToDouble() * 100 +
        lastTwo +
        (abs - abs.floorToDouble()),

    PriceFluctuation.none => abs,
  };

  return negative ? -shown : shown;
}

/// AnimatedPriceText
/// - Smoothly animates value changes
/// - Keeps numbers LTR even in Urdu/RTL UI
/// - Ticks a limited set of digits on an interval (see [PriceFluctuation])
/// - Green flash when the ticking digits go up, red when they go down
/// - Admin can remotely turn animation ON/OFF without touching call-sites
class AnimatedPriceText extends StatefulWidget {
  final double value;
  final String currencyPrefix;
  final TextStyle? style;

  final Duration changeAnim;
  final int decimals;

  final bool pulseDecimals;
  final Duration decimalPulse;

  /// Which digits tick. Defaults to [PriceFluctuation.decimals] so existing
  /// call sites keep their old behaviour.
  final PriceFluctuation fluctuation;
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
    this.fluctuation = PriceFluctuation.decimals,
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

  /// Frozen display value while the admin has animation switched off.
  double? _frozenValue;

  bool get _effectiveEnabled => widget.enabled && _remoteEnabled;
  bool get _canPulse => _effectiveEnabled && widget.pulseDecimals;
  PriceFluctuation get _mode =>
      effectivePriceFluctuation(widget.value, widget.fluctuation);

  bool get _canFluctuate {
    if (!_effectiveEnabled) return false;
    return switch (_mode) {
      PriceFluctuation.none => false,
      PriceFluctuation.decimals => widget.decimals >= 2,
      PriceFluctuation.lastTwoDigits => true,
    };
  }

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
        _frozenValue = null;
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
        oldWidget.fluctuation != widget.fluctuation ||
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

      // Freeze whatever is on screen right now.
      _frozenValue = _fluctuated(widget.value);

      _pulse.stop();
    } else if (!oldEnabled && newEnabled) {
      _frozenValue = null;
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

  /// Seeds the ticking digits from the real value so the first paint shows the
  /// admin figure exactly, before it starts moving.
  int _initialLastTwo(double v) {
    final abs = v.abs();

    return switch (_mode) {
      PriceFluctuation.lastTwoDigits => abs.floor() % 100,
      _ => (abs * 100.0).round() % 100,
    };
  }

  String _format(double v) {
    final fmt = NumberFormat("#,##0.${"0" * widget.decimals}", "en_US");
    return fmt.format(v);
  }

  double _fluctuated(double v) {
    if (!_canFluctuate) return v;

    return applyPriceFluctuation(
      value: v,
      mode: widget.fluctuation,
      lastTwo: _lastTwo,
    );
  }

  TextStyle _withFallbackWhite(TextStyle s) =>
      s.copyWith(color: s.color ?? Colors.white);

  Widget _buildPrice(double v) {
    final base =
    _withFallbackWhite(widget.style ?? Theme.of(context).textTheme.titleMedium!);
    final curStyle = base.copyWith(fontWeight: FontWeight.w600);
    final numStyle = base.copyWith(fontWeight: FontWeight.w800);

    final shown = _frozenValue ?? _fluctuated(v);

    final str = _format(shown);
    final parts = str.split(".");
    final intPart = parts.isNotEmpty ? parts[0] : str;
    final decPart = parts.length > 1 ? parts[1] : "";

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