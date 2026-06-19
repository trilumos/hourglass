import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/billing_providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../billing/billing_service.dart';
import 'pro_success_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// The custom "Sustain Pro" paywall. Reads live store prices from the offering;
/// never hardcodes prices. Handles every purchase/restore outcome.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProOffering? _offering;
  bool _loading = true;
  bool _busy = false;
  ProPlan _selected = ProPlan.yearly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await ref.read(billingServiceProvider).proOffering();
    if (!mounted) return;
    setState(() {
      _offering = o;
      _loading = false;
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _buy(ProPackage pkg) async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.success:
      case PurchaseOutcome.alreadyOwned:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProSuccessScreen()));
      case PurchaseOutcome.cancelled:
        break; // silent: cancelling is not an error
      case PurchaseOutcome.pending:
        _snack('Your purchase is processing. Pro unlocks once it is confirmed.');
      case PurchaseOutcome.error:
        _snack('That did not go through. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case RestoreOutcome.restoredPro:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProSuccessScreen()));
      case RestoreOutcome.nothingToRestore:
        _snack('No previous purchases found on this Google account.');
      case RestoreOutcome.error:
        _snack('Could not restore right now. Please try again.');
    }
  }

  Future<void> _manage() async {
    try {
      final ok = await launchUrl(
        Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) _snack('Could not open Google Play subscriptions.');
    } catch (_) {
      if (mounted) _snack('Could not open Google Play subscriptions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final pro = ref.watch(entitlementsProvider).pro;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: hg.textSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                Text('Sustain Pro',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary)),
                const SizedBox(height: HgSpacing.sm),
                Text('Train your focus, deeper.',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 16,
                        color: hg.textSecondary)),
                const SizedBox(height: HgSpacing.xl),
                ..._benefits(hg),
                const SizedBox(height: HgSpacing.xl),
                if (pro)
                  _ownedPanel(hg)
                else if (_loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(HgSpacing.xl),
                          child: CircularProgressIndicator()))
                else if (_offering == null)
                  _unavailable(hg)
                else
                  ..._plans(hg, _offering!),
                const SizedBox(height: HgSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text('Restore purchases',
                        style: TextStyle(
                            fontFamily: HgFont.sans, color: hg.textSecondary)),
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _benefits(HgTokens hg) {
    const items = [
      'Your Focus Score and Stamina, traced over time',
      'When you focus best, and your follow-through',
      'Personal bests and CSV export',
      'Every color theme, and session reuse',
      'Every Pro feature we add',
    ];
    return [
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: HgSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 18, color: hg.accent),
              const SizedBox(width: HgSpacing.sm),
              Expanded(
                  child: Text(t,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 15,
                          height: 1.35,
                          color: hg.textPrimary))),
            ],
          ),
        ),
    ];
  }

  List<Widget> _plans(HgTokens hg, ProOffering offering) {
    final monthly = offering.byPlan(ProPlan.monthly);
    final yearly = offering.byPlan(ProPlan.yearly);
    final lifetime = offering.byPlan(ProPlan.lifetime);
    String? savings;
    if (monthly != null && yearly != null && monthly.priceAmount > 0) {
      final pct =
          (100 * (1 - yearly.priceAmount / (monthly.priceAmount * 12))).round();
      if (pct > 0) savings = 'Save $pct%';
    }
    final selectedPkg = offering.byPlan(_selected) ?? offering.packages.first;
    return [
      if (monthly != null)
        _PlanTile(
            label: 'Monthly',
            price: monthly.priceString,
            note: 'Billed monthly, auto-renews until cancelled',
            selected: _selected == ProPlan.monthly,
            onTap: () => setState(() => _selected = ProPlan.monthly)),
      if (yearly != null)
        _PlanTile(
            label: 'Yearly',
            price: yearly.priceString,
            badge: savings,
            note: 'Billed yearly, auto-renews until cancelled',
            selected: _selected == ProPlan.yearly,
            onTap: () => setState(() => _selected = ProPlan.yearly)),
      if (lifetime != null)
        _PlanTile(
            label: 'Lifetime',
            price: lifetime.priceString,
            note: 'One-time payment, yours forever',
            selected: _selected == ProPlan.lifetime,
            onTap: () => setState(() => _selected = ProPlan.lifetime)),
      const SizedBox(height: HgSpacing.lg),
      PrimaryButton(
        label: _selected == ProPlan.lifetime ? 'Get Lifetime' : 'Start Pro',
        onPressed: _busy ? null : () => _buy(selectedPkg),
      ),
      const SizedBox(height: HgSpacing.sm),
      Text(
        _selected == ProPlan.lifetime
            ? 'A one-time payment. No subscription, no renewal.'
            : 'Auto-renews until cancelled. Manage or cancel anytime in Google Play.',
        textAlign: TextAlign.center,
        style:
            TextStyle(fontFamily: HgFont.sans, fontSize: 12, color: hg.textMuted),
      ),
      if (_selected != ProPlan.lifetime) ...[
        const SizedBox(height: HgSpacing.xs),
        Center(
          child: TextButton(
            onPressed: _manage,
            child: Text('Manage subscription',
                style: TextStyle(
                    fontFamily: HgFont.sans, color: hg.textSecondary)),
          ),
        ),
      ],
    ];
  }

  Widget _unavailable(HgTokens hg) => Container(
        padding: const EdgeInsets.all(HgSpacing.lg),
        decoration: BoxDecoration(
            color: hg.surfaceRaised,
            borderRadius: BorderRadius.circular(HgRadius.lg),
            border: Border.all(color: hg.hairline)),
        child: Text(
          'Pricing is unavailable right now. Check your connection and try again.',
          style: TextStyle(
              fontFamily: HgFont.sans, fontSize: 14, color: hg.textSecondary),
        ),
      );

  Widget _ownedPanel(HgTokens hg) => Container(
        padding: const EdgeInsets.all(HgSpacing.lg),
        decoration: BoxDecoration(
            color: hg.accentMuted,
            borderRadius: BorderRadius.circular(HgRadius.lg)),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: hg.accent),
            const SizedBox(width: HgSpacing.sm),
            Expanded(
                child: Text('You have Pro. Thank you.',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary))),
          ],
        ),
      );
}

class _PlanTile extends StatelessWidget {
  final String label;
  final String price;
  final String? note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.note,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: HgSpacing.sm),
        padding: const EdgeInsets.all(HgSpacing.md),
        decoration: BoxDecoration(
          color: selected ? hg.accentMuted : hg.surfaceRaised,
          borderRadius: BorderRadius.circular(HgRadius.lg),
          border: Border.all(
              color: selected ? hg.accent : hg.hairline,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Selection affordance.
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: HgSpacing.md),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? hg.accent : Colors.transparent,
                border: Border.all(
                    color: selected ? hg.accent : hg.hairline, width: 2),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 13, color: hg.onAccent)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hg.textPrimary)),
                    if (badge != null) ...[
                      const SizedBox(width: HgSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: hg.accent,
                            borderRadius: BorderRadius.circular(HgRadius.sm)),
                        child: Text(badge!,
                            style: TextStyle(
                                fontFamily: HgFont.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: hg.onAccent)),
                      ),
                    ],
                  ]),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(note!,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 12,
                            color: hg.textMuted)),
                  ],
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hg.textPrimary)),
          ],
        ),
      ),
    );
  }
}
