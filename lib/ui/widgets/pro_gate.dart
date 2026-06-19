import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/billing_providers.dart';
import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../paywall_screen.dart';

/// Shows [child] to Pro users, [upsell] to everyone else. Treats unknown/loading
/// as not-Pro (safe default); a real Pro user flips to [child] within a frame as
/// the cached entitlement loads.
class ProGate extends ConsumerWidget {
  final Widget child;
  final Widget upsell;
  const ProGate({super.key, required this.child, required this.upsell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(entitlementsProvider).pro;
    return pro ? child : upsell;
  }
}

/// The calm Insights upsell: a short honest line + a Get Pro action. No nag.
class ProUpsell extends StatelessWidget {
  final String headline;
  final String body;
  const ProUpsell({super.key, required this.headline, required this.body});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HgSpacing.lg),
      decoration: BoxDecoration(
        color: hg.surfaceRaised,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        border: Border.all(color: hg.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline,
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary)),
          const SizedBox(height: HgSpacing.sm),
          Text(body,
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  height: 1.4,
                  color: hg.textSecondary)),
          const SizedBox(height: HgSpacing.lg),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen())),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: HgSpacing.lg, vertical: HgSpacing.sm + 3),
              decoration: BoxDecoration(
                  color: hg.accent,
                  borderRadius: BorderRadius.circular(HgRadius.pill)),
              child: Text('See your full focus story',
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hg.onAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
