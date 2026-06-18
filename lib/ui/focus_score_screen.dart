import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// The Focus Score, hero-sized, with an honest explanation of how it's computed.
class FocusScoreScreen extends ConsumerWidget {
  const FocusScoreScreen({super.key});

  static const _paragraphs = <String>[
    'Your Focus Score reflects your recent focus ability — the average of your '
        'last 10 Flow Blocks, on a scale of 0 to 100.',
    "It builds up over your first several Flow Blocks. One great session won't "
        'jump you to 100 — focus is trained, not flipped.',
    'Completing a block, and pushing a little past it, raises your score. '
        'Giving up early lowers it. Only Flow Blocks of at least 2 minutes count.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final score = ref.watch(focusScoreProvider).asData?.value ?? 0;

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
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: score.toDouble()),
                    duration: HgMotion.slow,
                    curve: HgMotion.calm,
                    builder: (_, v, _) => Text(
                      '${v.round()}',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 104,
                        fontWeight: FontWeight.w600,
                        color: hg.accent,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.sm),
                Center(
                  child: Text(
                    'FOCUS SCORE',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: hg.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.xxl),
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
