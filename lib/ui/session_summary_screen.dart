import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import 'session_format.dart';
import 'start_again.dart';
import 'widgets/primary_button.dart';
import 'widgets/score_ring.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/surface_tile.dart';

/// Read-only detail for a single past session (tapped from the history list).
class SessionSummaryScreen extends ConsumerWidget {
  final SessionRecord session;
  const SessionSummaryScreen({super.key, required this.session});

  String get _outcome {
    if (session.abandoned) return 'Ended early';
    if (session.recordedFocus > session.plannedDuration) return 'Extended';
    return 'Completed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final isFlow = session.mode == SessionMode.flowBlock;
    final scored = isFlow && session.recordedFocus.inSeconds >= 120;
    final score = scored
        ? const FocusScoreCalculator().sessionScore(
            chosen: session.plannedDuration, actual: session.recordedFocus)
        : null;
    final planned = session.plannedDuration.inSeconds;
    final completion =
        planned <= 0 ? 1.0 : (session.recordedFocus.inSeconds / planned).clamp(0.0, 1.0);

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                ScreenHeader(title: formatDate(session.startedAt)),
                const SizedBox(height: HgSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: HgSpacing.xl),
                  child: Text(
                    formatClock(session.startedAt),
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 14,
                      color: hg.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),

                // Headline: focused vs planned + a completion bar.
                Text(
                  'Focused ${formatFocusDuration(session.recordedFocus)}',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: HgSpacing.xs),
                Text(
                  'of ${formatFocusDuration(session.plannedDuration)} planned',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 15,
                    color: hg.textSecondary,
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                _CompletionBar(fraction: completion),
                const SizedBox(height: HgSpacing.xl),

                // Fact bento — exact focused duration first.
                Row(
                  children: [
                    Expanded(
                      child: _Fact(
                        label: 'Duration',
                        value: formatExactDuration(session.recordedFocus),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Fact(label: 'Mode', value: modeLabel(session.mode))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Fact(label: 'Outcome', value: _outcome)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Fact(
                        label: 'Planned',
                        value: formatFocusDuration(session.plannedDuration),
                      ),
                    ),
                  ],
                ),

                if (session.intention.trim().isNotEmpty) ...[
                  const SizedBox(height: HgSpacing.xl),
                  Text(
                    'INTENTION',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: hg.textMuted,
                    ),
                  ),
                  const SizedBox(height: HgSpacing.sm),
                  Text(
                    session.intention.trim(),
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 16,
                      height: 1.4,
                      color: hg.textPrimary,
                    ),
                  ),
                ],

                if (isFlow) ...[
                  const SizedBox(height: HgSpacing.xl),
                  SurfaceTile(
                    child: score == null
                        ? Text(
                            'Not scored — Flow sessions under 2 minutes don’t count.',
                            style: TextStyle(
                              fontFamily: HgFont.sans,
                              fontSize: 14,
                              height: 1.4,
                              color: hg.textSecondary,
                            ),
                          )
                        : Row(
                            children: [
                              ScoreRing(
                                value: score,
                                size: 56,
                                stroke: 5,
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    fontFamily: HgFont.sans,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: hg.textPrimary,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: HgSpacing.md),
                              Expanded(
                                child: Text(
                                  'This session scored $score / 100 toward your Focus Score.',
                                  style: TextStyle(
                                    fontFamily: HgFont.sans,
                                    fontSize: 14,
                                    height: 1.4,
                                    color: hg.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],

                if (canReuse(session)) ...[
                  const SizedBox(height: HgSpacing.xl),
                  PrimaryButton(
                    label: 'Start again',
                    onPressed: () => startAgain(context, ref, session),
                  ),
                  const SizedBox(height: HgSpacing.xs),
                  Center(
                    child: Text(
                      'Repeat this exact ${modeLabel(session.mode).toLowerCase()} setup.',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        color: hg.textMuted,
                      ),
                    ),
                  ),
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

class _CompletionBar extends StatelessWidget {
  final double fraction;
  const _CompletionBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return ClipRRect(
      borderRadius: BorderRadius.circular(HgRadius.pill),
      child: Stack(
        children: [
          Container(height: 8, color: hg.hairline),
          TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: HgMotion.slow,
            curve: HgMotion.calm,
            builder: (context, f, _) => FractionallySizedBox(
              widthFactor: f,
              child: Container(height: 8, color: hg.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md, vertical: HgSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 10,
              letterSpacing: 1.5,
              color: hg.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: hg.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
