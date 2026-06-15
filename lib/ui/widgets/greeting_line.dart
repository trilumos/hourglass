import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../content/focus_quotes.dart';
import 'fade_up_text.dart';

/// The home screen's warm welcome: a varied greeting (chosen fresh each open)
/// plus a slide-up/fade encouragement line from the current time-of-day set.
/// Left-aligned, editorial.
class GreetingLine extends ConsumerStatefulWidget {
  const GreetingLine({super.key});

  @override
  ConsumerState<GreetingLine> createState() => _GreetingLineState();
}

class _GreetingLineState extends ConsumerState<GreetingLine> {
  static const _rotateEvery = Duration(seconds: 15);

  final Random _rng = Random();
  Timer? _timer;
  late TimeSegment _segment;
  int _encIndex = 0;
  String? _greeting;

  @override
  void initState() {
    super.initState();
    _segment = segmentFor(ref.read(clockProvider)());
    _encIndex = nextQuoteIndex(null, _lines.length, _rng);
    _timer = Timer.periodic(_rotateEvery, (_) => _advance());
  }

  List<FocusQuote> get _lines => kEncouragements[_segment]!;

  void _advance() {
    if (!mounted) return;
    setState(() => _encIndex = nextQuoteIndex(_encIndex, _lines.length, _rng));
  }

  // TODO(Plan 3): replace this hardcoded name with the user's name captured
  // during onboarding (stored in settings). See docs/project-context.md.
  static const _name = 'Deep';

  String _greetingFor(DateTime now, bool isNewUser, int streak) {
    return _greeting ??= () {
      final c = greetingCandidates(now, isNewUser: isNewUser, streak: streak);
      return c[nextQuoteIndex(null, c.length, _rng)];
    }();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final now = ref.watch(clockProvider)();
    final stats = ref.watch(homeStatsProvider).asData?.value;
    final greeting = _greetingFor(
      now,
      (stats?.sessionsCompleted ?? 1) == 0,
      stats?.streak ?? 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 29,
              fontWeight: FontWeight.w400,
              height: 1.15,
              letterSpacing: -0.3,
              color: hg.textPrimary,
            ),
            children: [
              TextSpan(text: '$greeting, '),
              TextSpan(
                text: _name,
                style: TextStyle(
                  color: hg.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(text: greetingPunctuation(greeting)),
            ],
          ),
        ),
        const SizedBox(height: HgSpacing.sm),
        // Fixed height (≈2 lines + slide room) so a longer quote never clips
        // during the transition and never resizes the hero.
        SizedBox(
          height: 58,
          width: double.infinity,
          child: Align(
            alignment: Alignment.topLeft,
            child: FadeUpText(
              text: '“${_lines[_encIndex].text}”',
              textAlign: TextAlign.start,
              distance: 8,
              highlightColor: hg.accent,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: hg.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
