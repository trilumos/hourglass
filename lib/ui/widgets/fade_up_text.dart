import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Animates text changes with a smooth slide-up + fade: the old line rises and
/// fades out while the new line rises into place and fades in. No flash.
class FadeUpText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Duration duration;
  final double distance;

  /// When set, any word wrapped in `*asterisks*` in [text] renders in this color
  /// (semibold) for a subtle highlight.
  final Color? highlightColor;

  const FadeUpText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.duration = const Duration(milliseconds: 550),
    this.distance = 12,
    this.highlightColor,
  });

  /// Builds spans from [text], rendering `*word*` segments in [highlight].
  static List<InlineSpan> spansFor(String text, Color? highlight) {
    if (highlight == null || !text.contains('*')) {
      return [TextSpan(text: text)];
    }
    final parts = text.split('*');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd
            ? TextStyle(color: highlight, fontWeight: FontWeight.w600)
            : null,
      ));
    }
    return spans;
  }

  @override
  State<FadeUpText> createState() => _FadeUpTextState();
}

class _FadeUpTextState extends State<FadeUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration, value: 1);
  late String _current = widget.text;
  String? _previous;

  @override
  void didUpdateWidget(FadeUpText old) {
    super.didUpdateWidget(old);
    if (widget.text != _current) {
      _previous = _current;
      _current = widget.text;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Top-aligned so quotes with different line counts don't jump vertically.
  Alignment get _align => switch (widget.textAlign) {
        TextAlign.center => Alignment.topCenter,
        TextAlign.right || TextAlign.end => Alignment.topRight,
        _ => Alignment.topLeft,
      };

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = HgMotion.calm.transform(_c.value);
          final d = widget.distance;
          return Stack(
            alignment: _align,
            children: [
              if (_previous != null && _c.value < 1)
                Opacity(
                  opacity: 1 - t,
                  child: Transform.translate(
                    offset: Offset(0, -d * t),
                    child: Text.rich(
                      TextSpan(
                        style: widget.style,
                        children:
                            FadeUpText.spansFor(_previous!, widget.highlightColor),
                      ),
                      textAlign: widget.textAlign,
                    ),
                  ),
                ),
              Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, d * (1 - t)),
                  child: Text.rich(
                    TextSpan(
                      style: widget.style,
                      children:
                          FadeUpText.spansFor(_current, widget.highlightColor),
                    ),
                    textAlign: widget.textAlign,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
