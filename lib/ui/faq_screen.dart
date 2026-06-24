import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/screen_background.dart';

/// One question and its answer.
class _Qa {
  final String q;
  final String a;
  const _Qa(this.q, this.a);
}

/// Plain, honest answers to common questions. No fabricated claims; mirrors how
/// the app actually behaves (Flow method, Focus Score / Stamina, free vs Pro,
/// payments via Google Play, privacy).
const _faqs = <_Qa>[
  _Qa(
    'What is Sustain?',
    'A focus app built around the Flow method: train your focus in deliberate '
        'blocks, then recover. It is a practice tool, not just a timer.',
  ),
  _Qa(
    'What are the three modes?',
    'Flow is one unbroken block of deep focus with recovery after. Pomodoro is '
        'focus in cycles with short breaks. Custom lets you design your own '
        'focus-and-break schedule.',
  ),
  _Qa(
    'What is the Focus Score?',
    'A 0 to 100 reflection of your recent focus ability, from your Flow sessions '
        '(weighted by length, finishing, and time spent past your goal). It is a '
        'rolling average of your last several sessions, so it moves gently rather '
        'than jumping after one session.',
  ),
  _Qa(
    'What is Focus Stamina?',
    'The length of unbroken focus you can hold. It is unset until your first '
        'recorded Flow session, which sets your starting point. After that it '
        'rises when you finish a block, or when you sustain longer than your '
        'current stamina. Ending early below it never lowers it. There is no cap; '
        '90 minutes is shown as a reference, not a limit.',
  ),
  _Qa(
    'Why did my short session not count?',
    'A Flow block under 2 minutes records nothing, so it never skews your streak, '
        'score, or history. Pomodoro and Custom keep whatever focus you actually did.',
  ),
  _Qa(
    'What is free, and what is Pro?',
    'Free includes the full focus loop (all three modes), your Focus Score, '
        'streak, today / total, the basic Insights (records and the consistency '
        'heatmap), CSV history export, the Sand look, and session sound cues. Pro '
        'adds the full Insights depth (Focus Score and Stamina over time, your peak '
        'window, follow-through, personal bests, average session, and a PDF Focus '
        'Report), every color theme, unlimited longer pauses (up to 10 minutes), '
        'keeping a Pomodoro or Custom session going past its end, session reuse, '
        'and every Pro feature added later.',
  ),
  _Qa(
    'How do payments work?',
    'Through Google Play. Google shows the price in your local currency, handles '
        'the payment and any tax, and offers your usual payment methods. A monthly '
        'or yearly plan renews until you cancel; lifetime is a single one-time '
        'purchase that never expires.',
  ),
  _Qa(
    'How do I restore a purchase, or cancel?',
    'Open the Sustain Pro page and tap Restore purchases to bring back a previous '
        'purchase on the same Google account. To cancel or change a subscription, '
        'use Manage subscription on that page, which opens Google Play. A lifetime '
        'purchase has nothing to cancel.',
  ),
  _Qa(
    'Is my data private?',
    'Yes. Your sessions and stats stay on your device. Sustain has no accounts and '
        'collects no analytics. Purchases are handled by Google Play and RevenueCat '
        'using an anonymous id and the purchase receipt; we never see your payment '
        'details.',
  ),
  _Qa(
    'Can I export my data?',
    'Yes. Your raw session history exports as a CSV from the History screen — that '
        'is free, because your data is yours. Pro adds a polished PDF Focus Report '
        'from Insights for the whole story in one shareable document.',
  ),
  _Qa(
    'Are there ads?',
    'No. Sustain has no ads, and it will not send guilt-trip or "come back" '
        'notifications. Only reminders you set yourself.',
  ),
  _Qa(
    'How do I clear everything?',
    'Settings has Clear all data, which deletes every session, your stats, your '
        'profile, and your preferences, then starts you fresh. It cannot be undone.',
  ),
];

/// A calm, expandable FAQ. Reached from Settings.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: HgSize.iconMd,
                      color: hg.textSecondary,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: HgSpacing.xs),
                    Text(
                      'FAQ',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HgSpacing.lg),
                for (final qa in _faqs) _FaqTile(qa),
                const SizedBox(height: HgSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tap-to-expand question. Smoothly reveals its answer; chevron rotates.
class _FaqTile extends StatefulWidget {
  final _Qa qa;
  const _FaqTile(this.qa);

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.qa.q,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: hg.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: HgSpacing.sm),
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: HgMotion.fast,
                    curve: HgMotion.calm,
                    child: Icon(Icons.chevron_right_rounded,
                        color: hg.textMuted, size: HgSize.iconMd),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: HgSpacing.sm),
              child: Text(
                widget.qa.a,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  height: 1.5,
                  color: hg.textSecondary,
                ),
              ),
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: HgMotion.fast,
            sizeCurve: HgMotion.calm,
          ),
          Divider(height: 1, thickness: 1, color: hg.hairline),
        ],
      ),
    );
  }
}
