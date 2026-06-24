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

/// The custom "Sustain Pro" paywall.
/// - Non-Pro users: two-page flow — page 1 = features, page 2 = pricing/buy.
/// - Pro users: management view — manage subscription, change plan, restore.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  final _pageCtrl = PageController();
  ProOffering? _offering;
  bool _loading = true;
  bool _busy = false;
  ProPlan _selected = ProPlan.yearly;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
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
        break;
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

  Future<void> _manageSubscription() async {
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

  void _goToPricing() {
    _pageCtrl.animateToPage(1,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final pro = ref.watch(entitlementsProvider).pro;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: pro ? _proManagement(hg) : _paywallPages(hg),
        ),
      ),
    );
  }

  // ── Pro management (when already subscribed) ────────────────────────────────

  Widget _proManagement(HgTokens hg) {
    return Padding(
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
          Row(children: [
            Icon(Icons.check_circle_rounded, size: 28, color: hg.accent),
            const SizedBox(width: HgSpacing.sm),
            Text('Sustain Pro',
                style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: hg.textPrimary)),
          ]),
          const SizedBox(height: HgSpacing.xs),
          Text('Thank you for supporting Sustain.',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 15,
                  height: 1.4,
                  color: hg.textSecondary)),
          const SizedBox(height: HgSpacing.xl),
          _ManagementTile(
            icon: Icons.open_in_new_rounded,
            title: 'Manage subscription',
            subtitle: 'Cancel, pause, or update billing in Google Play.',
            hg: hg,
            onTap: _busy ? null : _manageSubscription,
          ),
          const SizedBox(height: HgSpacing.sm),
          _ManagementTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Change plan',
            subtitle: 'Switch between monthly, yearly, or lifetime.',
            hg: hg,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ChangePlanScreen(
                  offering: _offering,
                  loading: _loading,
                  busy: _busy,
                  selected: _selected,
                  onSelect: (p) => setState(() => _selected = p),
                  onBuy: () {
                    if (_offering == null) return;
                    final pkg = _offering!.byPlan(_selected) ??
                        _offering!.packages.first;
                    _buy(pkg);
                  },
                  onRestore: _restore,
                ),
              ),
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          _ManagementTile(
            icon: Icons.restore_rounded,
            title: 'Restore purchases',
            subtitle: 'Recover a previous purchase on this account.',
            hg: hg,
            onTap: _busy ? null : _restore,
          ),
          const SizedBox(height: HgSpacing.xxl),
        ],
      ),
    );
  }

  // ── Two-page paywall (non-Pro) ───────────────────────────────────────────────

  Widget _paywallPages(HgTokens hg) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            children: [
              _featuresPage(hg),
              _pricingPage(hg),
            ],
          ),
        ),
        // Page dots.
        Padding(
          padding: const EdgeInsets.only(bottom: HgSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _pageIndex == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _pageIndex == i ? hg.accent : hg.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _featuresPage(HgTokens hg) {
    return Padding(
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
          const SizedBox(height: HgSpacing.sm),
          Text('Sustain Pro',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary)),
          const SizedBox(height: HgSpacing.xs),
          Text('Train your focus, deeper.',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 16,
                  color: hg.textSecondary)),
          const SizedBox(height: HgSpacing.xl),
          Text('WHAT YOU UNLOCK',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: hg.textMuted)),
          const SizedBox(height: HgSpacing.md),
          ..._benefits(hg),
          const SizedBox(height: HgSpacing.xl),
          PrimaryButton(
            label: 'See pricing →',
            onPressed: _goToPricing,
          ),
          const SizedBox(height: HgSpacing.lg),
        ],
      ),
    );
  }

  Widget _pricingPage(HgTokens hg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: ListView(
        children: [
          const SizedBox(height: HgSpacing.sm),
          // Header row: back + close.
          Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: hg.textSecondary),
              onPressed: () => _pageCtrl.animateToPage(0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic),
              tooltip: 'Back',
              visualDensity: VisualDensity.compact,
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close_rounded, color: hg.textSecondary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ]),
          const SizedBox(height: HgSpacing.sm),
          Text('Choose your plan',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary)),
          const SizedBox(height: HgSpacing.xs),
          Text('Unlock everything. Cancel anytime.',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  color: hg.textSecondary)),
          const SizedBox(height: HgSpacing.xl),
          if (_loading)
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
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  List<Widget> _benefits(HgTokens hg) {
    const items = <(IconData, String, String)>[
      (
        Icons.insights_rounded,
        'Deep insights',
        'Your Focus Score and Stamina traced over time, your best hours, and your follow-through.'
      ),
      (
        Icons.workspace_premium_rounded,
        'Personal bests + PDF report',
        'Records and milestones, plus a detailed focus report you can export and keep.'
      ),
      (
        Icons.pause_circle_outline_rounded,
        'Unlimited, longer pauses',
        'Step away mid-session — for longer, as often as you need — without losing your block.'
      ),
      (
        Icons.add_circle_outline_rounded,
        'Keep any session going',
        'Add more blocks to a Pomodoro or Custom session on the fly, right as it ends.'
      ),
      (
        Icons.palette_outlined,
        'Every color theme',
        'All premium themes — now and every one we add — plus one-tap session reuse.'
      ),
      (
        Icons.auto_awesome_rounded,
        'Everything new, included',
        'Every Pro feature we ship lands in your plan automatically.'
      ),
    ];
    return [
      for (final (icon, title, body) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: HgSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hg.accentMuted,
                  borderRadius: BorderRadius.circular(HgRadius.md),
                ),
                child: Icon(icon, size: 20, color: hg.accent),
              ),
              const SizedBox(width: HgSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: hg.textPrimary)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 13,
                            height: 1.35,
                            color: hg.textSecondary)),
                  ],
                ),
              ),
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
      if (yearly != null)
        _PlanTile(
            label: 'Yearly',
            price: yearly.priceString,
            badge: savings ?? 'Best value',
            note: 'Billed yearly, auto-renews until cancelled',
            selected: _selected == ProPlan.yearly,
            onTap: () => setState(() => _selected = ProPlan.yearly)),
      if (monthly != null)
        _PlanTile(
            label: 'Monthly',
            price: monthly.priceString,
            note: 'Billed monthly, auto-renews until cancelled',
            selected: _selected == ProPlan.monthly,
            onTap: () => setState(() => _selected = ProPlan.monthly)),
      if (lifetime != null)
        _PlanTile(
            label: 'Lifetime',
            price: lifetime.priceString,
            note: 'One-time payment — own it forever',
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
}

// ── Change Plan screen (used from Pro management) ────────────────────────────

class _ChangePlanScreen extends ConsumerStatefulWidget {
  final ProOffering? offering;
  final bool loading;
  final bool busy;
  final ProPlan selected;
  final ValueChanged<ProPlan> onSelect;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  const _ChangePlanScreen({
    required this.offering,
    required this.loading,
    required this.busy,
    required this.selected,
    required this.onSelect,
    required this.onBuy,
    required this.onRestore,
  });

  @override
  ConsumerState<_ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends ConsumerState<_ChangePlanScreen> {
  late ProPlan _selected = widget.selected;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _restore() async {
    final outcome = await ref.read(billingServiceProvider).restore();
    if (!mounted) return;
    switch (outcome) {
      case RestoreOutcome.restoredPro:
        Navigator.of(context).popUntil((r) => r.isFirst);
      case RestoreOutcome.nothingToRestore:
        _snack('No previous purchases found on this Google account.');
      case RestoreOutcome.error:
        _snack('Could not restore right now. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final offering = widget.offering;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                Row(children: [
                  IconButton(
                    icon:
                        Icon(Icons.arrow_back_rounded, color: hg.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    visualDensity: VisualDensity.compact,
                  ),
                ]),
                const SizedBox(height: HgSpacing.sm),
                Text('Change plan',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary)),
                const SizedBox(height: HgSpacing.xs),
                Text(
                  'Select a new plan below. Google Play handles the switch; '
                  'any unused time on your current plan is credited.',
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 14,
                      height: 1.4,
                      color: hg.textSecondary),
                ),
                const SizedBox(height: HgSpacing.xl),
                if (widget.loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(HgSpacing.xl),
                          child: CircularProgressIndicator()))
                else if (offering == null)
                  Container(
                    padding: const EdgeInsets.all(HgSpacing.lg),
                    decoration: BoxDecoration(
                        color: hg.surfaceRaised,
                        borderRadius: BorderRadius.circular(HgRadius.lg),
                        border: Border.all(color: hg.hairline)),
                    child: Text(
                      'Pricing is unavailable right now. Check your connection.',
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 14,
                          color: hg.textSecondary),
                    ),
                  )
                else ...[
                  ..._buildTiles(hg, offering),
                  const SizedBox(height: HgSpacing.lg),
                  PrimaryButton(
                    label: _selected == ProPlan.lifetime
                        ? 'Get Lifetime'
                        : 'Switch plan',
                    onPressed: widget.busy ? null : widget.onBuy,
                  ),
                  const SizedBox(height: HgSpacing.sm),
                  Text(
                    _selected == ProPlan.lifetime
                        ? 'A one-time payment. No subscription, no renewal.'
                        : 'Auto-renews until cancelled. Manage or cancel anytime in Google Play.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 12,
                        color: hg.textMuted),
                  ),
                ],
                const SizedBox(height: HgSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: _restore,
                    child: Text('Restore purchases',
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            color: hg.textSecondary)),
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

  List<Widget> _buildTiles(HgTokens hg, ProOffering offering) {
    final monthly = offering.byPlan(ProPlan.monthly);
    final yearly = offering.byPlan(ProPlan.yearly);
    final lifetime = offering.byPlan(ProPlan.lifetime);
    String? savings;
    if (monthly != null && yearly != null && monthly.priceAmount > 0) {
      final pct =
          (100 * (1 - yearly.priceAmount / (monthly.priceAmount * 12))).round();
      if (pct > 0) savings = 'Save $pct%';
    }
    return [
      if (yearly != null)
        _PlanTile(
            label: 'Yearly',
            price: yearly.priceString,
            badge: savings ?? 'Best value',
            note: 'Billed yearly, auto-renews until cancelled',
            selected: _selected == ProPlan.yearly,
            onTap: () => setState(() => _selected = ProPlan.yearly)),
      if (monthly != null)
        _PlanTile(
            label: 'Monthly',
            price: monthly.priceString,
            note: 'Billed monthly, auto-renews until cancelled',
            selected: _selected == ProPlan.monthly,
            onTap: () => setState(() => _selected = ProPlan.monthly)),
      if (lifetime != null)
        _PlanTile(
            label: 'Lifetime',
            price: lifetime.priceString,
            note: 'One-time payment — own it forever',
            selected: _selected == ProPlan.lifetime,
            onTap: () => setState(() => _selected = ProPlan.lifetime)),
    ];
  }
}

// ── Shared tile widgets ──────────────────────────────────────────────────────

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final HgTokens hg;
  final VoidCallback? onTap;

  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(HgSpacing.md),
        decoration: BoxDecoration(
            color: hg.surfaceRaised,
            borderRadius: BorderRadius.circular(HgRadius.lg),
            border: Border.all(color: hg.hairline)),
        child: Row(
          children: [
            Icon(icon, size: 22, color: hg.accent),
            const SizedBox(width: HgSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: hg.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 13,
                          height: 1.35,
                          color: hg.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: hg.textMuted),
          ],
        ),
      ),
    );
  }
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
