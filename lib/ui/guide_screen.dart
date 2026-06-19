import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/surface_tile.dart';

/// "How it works" — an honest, calm explainer of the app's purpose, the
/// Flow method, the three modes, the Focus Score, and your numbers.
/// Copy follows the brand honesty rule: no invented science or stats.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _modes = <(String, String)>[
    (
      'Flow',
      'One unbroken block of deep focus. Set an intention, flip the hourglass, '
          'and ride the Struggle into Flow. It is the only mode that feeds your '
          'Focus Score, and the one that grows your focus stamina over time.'
    ),
    (
      'Pomodoro',
      'Classic fixed blocks with short breaks (25/5, 50/10, 52/17, 90/15). You '
          'pick how many blocks; a longer break lands every fourth.'
    ),
    (
      'Custom',
      'Your exact focus time, split into equal variable-length blocks with '
          'automatic rests (about one part rest to five parts focus). You set '
          'the focus time and the number of blocks.'
    ),
  ];

  static const _numbers = <(String, String)>[
    ('Today', 'The focus you have logged since midnight.'),
    ('Streak', 'Consecutive days you have focused, including today.'),
    ('Total', 'Your lifetime focus across every session.'),
    ('Records', 'Your best streak, longest session, and this week’s focus.'),
  ];

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'How it works'),
                const SizedBox(height: HgSpacing.xl),

                Text(
                  'Train your focus like an athlete.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.4,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                _Body(
                  'Sustain is focus training, not just a timer. You build the '
                  'ability to concentrate deeply, and you learn to recover from '
                  'it, so your focus grows stronger over time.',
                ),

                _Heading('THE FLOW METHOD'),
                _Body(
                  'Our core method. Set a small intention, flip the hourglass, '
                  'and begin. The first few minutes are the Struggle — that '
                  'resistance is expected and temporary. Push through it and you '
                  'settle into Flow. Afterwards comes a short, phone-free '
                  'recovery. The more you practise, the longer you can hold a '
                  'block.',
                ),

                _Heading('THE THREE MODES'),
                for (final m in _modes) ...[
                  _ModeCard(name: m.$1, description: m.$2),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: HgSpacing.md),
                _Heading('YOUR FOCUS SCORE'),
                _Body(
                  'A reading from 0 to 100 of your recent focus ability: the '
                  'average of your last 10 Flow sessions. It builds up over your '
                  'first several blocks, and it rewards finishing what you '
                  'start. Only Flow sessions count toward it. Open the Focus Score '
                  'page any time to see how it is calculated.',
                ),

                _Heading('YOUR AVERAGE FOCUS'),
                _Body(
                  'Your typical focused time per session, across every mode. '
                  'Where the Focus Score reflects ability and counts only Flow, '
                  'your average is the simple picture of how long you usually '
                  'focus. Flow sessions under 2 minutes are ignored, so a quick '
                  'false start never drags it down.',
                ),

                _Heading('YOUR NUMBERS'),
                for (final n in _numbers) _DefRow(term: n.$1, def: n.$2),

                _Heading('YOUR PRIVACY'),
                _Body(
                  'Sustain works fully offline. Your sessions, stats, and '
                  'profile live only on your device. We collect nothing.',
                ),
                const SizedBox(height: HgSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(top: HgSpacing.xl, bottom: HgSpacing.md),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
          color: hg.textMuted,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 15,
        height: 1.6,
        color: hg.textSecondary,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String name;
  final String description;
  const _ModeCard({required this.name, required this.description});
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: hg.accent,
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            description,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 14,
              height: 1.5,
              color: hg.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefRow extends StatelessWidget {
  final String term;
  final String def;
  const _DefRow({required this.term, required this.def});
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            term,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            def,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 14,
              height: 1.45,
              color: hg.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
