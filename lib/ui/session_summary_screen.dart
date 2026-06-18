import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import 'session_format.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// Read-only detail for a single past session (tapped from the history list).
class SessionSummaryScreen extends StatelessWidget {
  final SessionRecord session;
  const SessionSummaryScreen({super.key, required this.session});

  String get _outcome {
    if (session.abandoned) return 'Ended early';
    if (session.recordedFocus > session.plannedDuration) return 'Extended';
    return 'Completed';
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final isFlow = session.mode == SessionMode.flowBlock;
    final scored = isFlow && session.recordedFocus.inSeconds >= 120;
    final score = scored
        ? const FocusScoreCalculator().sessionScore(
            chosen: session.plannedDuration, actual: session.recordedFocus)
        : null;

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

                // Focused-vs-planned, the headline of the session.
                Text(
                  'Focused ${formatFocusDuration(session.recordedFocus)} '
                  'of ${formatFocusDuration(session.plannedDuration)}',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),

                _Row(label: 'Mode', value: modeLabel(session.mode)),
                if (session.intention.trim().isNotEmpty)
                  _Row(label: 'Intention', value: session.intention.trim()),
                _Row(label: 'Outcome', value: _outcome),

                if (isFlow) ...[
                  const SizedBox(height: HgSpacing.lg),
                  _ScoreCard(score: score),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 11,
                letterSpacing: 1.5,
                color: hg.textMuted,
              ),
            ),
          ),
          const SizedBox(width: HgSpacing.md),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                height: 1.35,
                color: hg.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  /// null = a Flow Block under 2 minutes (not scored).
  final int? score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final s = score;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HgSpacing.md),
      decoration: BoxDecoration(
        color: hg.surfaceRaised,
        borderRadius: BorderRadius.circular(HgRadius.md),
        border: Border.all(color: hg.hairline),
      ),
      child: s == null
          ? Text(
              'Not scored — Flow Blocks under 2 minutes don’t count.',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                height: 1.4,
                color: hg.textSecondary,
              ),
            )
          : Row(
              children: [
                Text(
                  '$s',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: hg.accent,
                    height: 1,
                  ),
                ),
                const SizedBox(width: HgSpacing.md),
                Expanded(
                  child: Text(
                    'This session scored $s / 100 toward your Focus Score.',
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
    );
  }
}
