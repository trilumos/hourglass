import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/score_ring.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// The Focus Score as an instrument reading: a radial gauge with the number in
/// tabular figures, then an honest, plain-language explanation. No "level up"
/// claim (Levels is V2), no invented science (brand honesty rule).
class FocusScoreScreen extends ConsumerWidget {
  const FocusScoreScreen({super.key});

  static const _paragraphs = <String>[
    'Your Focus Score is the average of your last 10 Flow Blocks, on a scale of '
        '0 to 100. It reflects your recent focus ability, not your whole history.',
    "It builds up over your first several Flow Blocks. One great session won't "
        'jump you to 100 — focus is trained, not flipped.',
    'Completing a block, and pushing a little past it, raises your score. '
        'Giving up early lowers it. Only Flow Blocks of at least 2 minutes count.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final score = ref.watch(focusScoreProvider).value ?? 0;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Focus Score'),
                const SizedBox(height: HgSpacing.xxl),

                // Hero gauge (centered).
                Center(
                  child: ScoreRing(
                    value: score,
                    size: 224,
                    stroke: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: score.toDouble()),
                          duration: HgMotion.slow,
                          curve: HgMotion.calm,
                          builder: (_, v, _) => Text(
                            '${v.round()}',
                            style: TextStyle(
                              fontFamily: HgFont.sans,
                              fontSize: 68,
                              fontWeight: FontWeight.w600,
                              height: 1,
                              letterSpacing: -1,
                              color: hg.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'OF 100',
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                            color: hg.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.xxl),

                // Explanation (left-aligned content band).
                Text(
                  'HOW IT’S CALCULATED',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: hg.textMuted,
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                for (final para in _paragraphs) ...[
                  Text(
                    para,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 15,
                      height: 1.55,
                      color: hg.textSecondary,
                    ),
                  ),
                  const SizedBox(height: HgSpacing.lg),
                ],
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
