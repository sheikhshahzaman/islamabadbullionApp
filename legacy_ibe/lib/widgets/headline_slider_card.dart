import "dart:async";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../providers/app_settings.dart";
import "../providers/headlines_provider.dart";

class HeadlineSliderCard extends StatefulWidget {
  final Color bg;
  final Color card;
  final Color accent;

  const HeadlineSliderCard({
    super.key,
    required this.bg,
    required this.card,
    required this.accent,
  });

  @override
  State<HeadlineSliderCard> createState() => _HeadlineSliderCardState();
}

class _HeadlineSliderCardState extends State<HeadlineSliderCard>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _marqueeController;

  // Smooth speed (pixels per frame tick)
  static const double _speed = 0.7;

  // Width of one full cycle of text (used to loop seamlessly)
  double _singleCycleWidth = 0;

  @override
  void initState() {
    super.initState();

    // Provider start (safe)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HeadlinesProvider>().start();
    });

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // long-running controller
    )
      ..addListener(_onMarqueeTick)
      ..repeat();
  }

  void _onMarqueeTick() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    if (_singleCycleWidth <= 0) return;

    final next = _scrollController.offset + _speed;

    // Loop back once one cycle is consumed (seamless because text is duplicated)
    if (next >= _singleCycleWidth) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _marqueeController
      ..removeListener(_onMarqueeTick)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final p = context.watch<HeadlinesProvider>();

    if (p.items.isEmpty) {
      // ✅ Hide card when no headlines (keeps UI clean)
      return const SizedBox.shrink();
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 14,
        );

    final headlines = p.items
        .map((e) => settings.isUrdu ? e.ur : e.en)
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (headlines.isEmpty) return const SizedBox.shrink();

    // If more than two headlines are active, add " - " between them
    // (If you want separator for 2 headlines also, change > 2 to > 1)
    final separator = headlines.length > 1 ? "  -  " : "   ";

    final joinedText = headlines.join(separator);

    // Add spacing at end so loop feels natural
    const loopGap = "      ";
    final cycleText = "$joinedText$loopGap";

    // Measure width of one cycle for seamless reset
    final tp = TextPainter(
      text: TextSpan(text: cycleText, style: textStyle),
      maxLines: 1,
      textDirection: settings.isUrdu ? TextDirection.rtl : TextDirection.ltr,
    )..layout();

    _singleCycleWidth = tp.width + 40; // + gap between duplicate copies

    return Card(
      color: widget.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: widget.accent.withOpacity(0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              Icon(Icons.campaign, color: widget.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        Text(
                          cycleText,
                          maxLines: 1,
                          softWrap: false,
                          textAlign:
                          settings.isUrdu ? TextAlign.right : TextAlign.left,
                          textDirection: settings.isUrdu
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: textStyle,
                        ),
                        const SizedBox(width: 40),
                        Text(
                          cycleText,
                          maxLines: 1,
                          softWrap: false,
                          textAlign:
                          settings.isUrdu ? TextAlign.right : TextAlign.left,
                          textDirection: settings.isUrdu
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: textStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}