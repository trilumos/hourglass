import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// Serene "you're Pro" confirmation (completion-screen register: gentle haptic,
/// never confetti). Continue returns to Home, clearing the paywall + origin.
class ProSuccessScreen extends StatefulWidget {
  const ProSuccessScreen({super.key});
  @override
  State<ProSuccessScreen> createState() => _ProSuccessScreenState();
}

class _ProSuccessScreenState extends State<ProSuccessScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 56, color: hg.accent),
                const SizedBox(height: HgSpacing.lg),
                Text("You're Pro",
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: hg.textPrimary)),
                const SizedBox(height: HgSpacing.md),
                Text(
                  'Your full focus story is unlocked. Thank you for supporting Sustain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 15,
                      height: 1.5,
                      color: hg.textSecondary),
                ),
                const SizedBox(height: HgSpacing.xl),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
