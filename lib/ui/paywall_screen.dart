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
  ProStatus? _status;
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
    final svc = ref.read(billingServiceProvider);
    final o = await svc.proOffering();
    // Only the management view needs the active-purchase details.
    final s = ref.read(entitlementsProvider).pro ? await svc.proStatus() : null;
    if (!mounted) return;
    setState(() {
      _offering = o;
      _status = s;
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
          const SizedBox(height: HgSpacing.lg),
          _StatusCard(status: _status, loading: _loading, hg: hg),
          const SizedBox(height: HgSpacing.lg),
          // A Lifetime owner has no subscription to manage — only restore.
          // Subscribers get the Play subscription link. Plan changes are handled
          // in Google Play (cancel, then resubscribe to the plan you want) — we
          // intentionally don't offer an in-app plan switch, which Google can't
          // do cleanly across separate products and risks double-billing.
          if (_status?.isLifetime != true) ...[
            _ManagementTile(
              icon: Icons.open_in_new_rounded,
              title: 'Manage subscription',
              subtitle: 'Cancel or update billing in Google Play. To switch '
                  'plans, cancel here, then resubscribe.',
              hg: hg,
              onTap: _busy ? null : _manageSubscription,
            ),
            const SizedBox(height: HgSpacing.sm),
          ],
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
          Text('FREE VS PRO',
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: hg.textMuted)),
          const SizedBox(height: HgSpacing.md),
          _comparison(hg),
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
          Text('Unlock every Pro feature. Cancel anytime.',
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

  /// A compact table showing, at a glance, exactly what Pro changes. Only the
  /// rows that differ between Free and Pro — the deltas, not the whole app.
  Widget _comparison(HgTokens hg) {
    const rows = <(String, String, String)>[
      ('Insights over time', '—', 'Full'),
      ('Color themes', 'Sand', 'All 9 · Lifetime only'),
      ('Mid-session pauses', '3 × 3 min', 'Unlimited × 10 min'),
      ('PDF Focus Report', '—', 'Yes'),
      ('Average session stat', '—', 'Yes'),
      ('New Pro features', '—', 'Included'),
    ];
    Widget cell(String text, {required bool pro}) {
      final isDash = text == '—';
      return Expanded(
        flex: 4,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 12.5,
            fontWeight: pro ? FontWeight.w600 : FontWeight.w400,
            color: isDash
                ? hg.textMuted
                : (pro ? hg.accent : hg.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: hg.surfaceRaised,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        border: Border.all(color: hg.hairline),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md, vertical: HgSpacing.sm),
      child: Column(
        children: [
          // Header row.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
            child: Row(
              children: [
                const Expanded(flex: 7, child: SizedBox()),
                Expanded(
                  flex: 4,
                  child: Text('Free',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: hg.textMuted)),
                ),
                Expanded(
                  flex: 4,
                  child: Text('Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: hg.accent)),
                ),
              ],
            ),
          ),
          for (final (label, free, pro) in rows) ...[
            Divider(height: 1, color: hg.hairline),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Text(label,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 13,
                            color: hg.textPrimary)),
                  ),
                  cell(free, pro: false),
                  cell(pro, pro: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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
        'Keep going, and repeat',
        'Add blocks to a Pomodoro or Custom session as it ends, and start again from any past session in one tap.'
      ),
      (
        Icons.palette_outlined,
        'Every color theme — with Lifetime',
        'Lifetime includes all 9 premium themes, plus every one we add, yours '
            'forever. On Monthly and Yearly, themes are sold separately — buy one '
            'once and you keep it, even if you cancel.'
      ),
      (
        Icons.auto_awesome_rounded,
        'New Pro features, included',
        'Every Pro feature we ship lands in your plan automatically. '
            'Optional services like cloud backup are separate.'
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
    final selectedPkg = offering.byPlan(_selected) ?? offering.packages.first;
    return [
      ...buildPlanTiles(
        offering: offering,
        selected: _selected,
        onSelect: (p) => setState(() => _selected = p),
      ),
      const SizedBox(height: HgSpacing.lg),
      PrimaryButton(
        label: _selected == ProPlan.lifetime ? 'Get Lifetime' : 'Start Pro',
        onPressed: _busy ? null : () => _buy(selectedPkg),
      ),
      const SizedBox(height: HgSpacing.sm),
      Text(
        _selected == ProPlan.lifetime
            ? 'A one-time payment — no subscription, no renewal. Includes every color theme, and every Pro feature we add later. Optional services like cloud backup are separate.'
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

/// "≈ ₹X/mo" derived from an annual package, for the Yearly tile. Null when it
/// can't be computed cleanly (missing price, unrecognised currency formatting).
String? _perMonthLabel(ProPackage? yearly) {
  if (yearly == null || yearly.priceAmount <= 0) return null;
  final ps = yearly.priceString.trim();
  // The currency symbol = the price string minus digits, separators, and spaces.
  final symbol = ps.replaceAll(RegExp(r'[0-9.,\s ]'), '');
  if (symbol.isEmpty) return null;
  final per = yearly.priceAmount / 12;
  final num = per >= 100 ? per.round().toString() : per.toStringAsFixed(2);
  // Mirror the symbol's side (prefix for ₹/$/€/£, suffix for e.g. "199 kr").
  final symbolFirst = RegExp(r'^[^0-9]').hasMatch(ps);
  final money = symbolFirst ? '$symbol$num' : '$num$symbol';
  return '≈ $money/mo';
}

/// The plan tiles, shared by the paywall pricing page and the Change-plan screen.
List<Widget> buildPlanTiles({
  required ProOffering offering,
  required ProPlan selected,
  required ValueChanged<ProPlan> onSelect,
}) {
  final monthly = offering.byPlan(ProPlan.monthly);
  final yearly = offering.byPlan(ProPlan.yearly);
  final lifetime = offering.byPlan(ProPlan.lifetime);
  String? savings;
  if (monthly != null && yearly != null && monthly.priceAmount > 0) {
    final pct =
        (100 * (1 - yearly.priceAmount / (monthly.priceAmount * 12))).round();
    if (pct > 0) savings = 'Save $pct%';
  }
  final perMonth = _perMonthLabel(yearly);
  return [
    if (yearly != null)
      _PlanTile(
          label: 'Yearly',
          price: yearly.priceString,
          badge: savings ?? 'Best value',
          note: perMonth != null
              ? '$perMonth · billed yearly, auto-renews'
              : 'Billed yearly, auto-renews until cancelled',
          selected: selected == ProPlan.yearly,
          onTap: () => onSelect(ProPlan.yearly)),
    if (monthly != null)
      _PlanTile(
          label: 'Monthly',
          price: monthly.priceString,
          note: 'Billed monthly, auto-renews until cancelled',
          selected: selected == ProPlan.monthly,
          onTap: () => onSelect(ProPlan.monthly)),
    if (lifetime != null)
      _PlanTile(
          label: 'Lifetime',
          price: lifetime.priceString,
          // The one place themes are called out on the tiles: stated positively
          // on Lifetime only. Monthly/Yearly stay silent by design — the rule is
          // spelled out in the comparison table and the feature list above.
          badge: 'Own forever · all themes',
          note: 'One-time payment — no subscription, no renewal',
          selected: selected == ProPlan.lifetime,
          onTap: () => onSelect(ProPlan.lifetime)),
  ];
}

// ── Shared tile widgets ──────────────────────────────────────────────────────

/// The active-plan card at the top of the Pro management view: which plan, and
/// when it renews or ends. Degrades gracefully when the store can't report it.
class _StatusCard extends StatelessWidget {
  final ProStatus? status;
  final bool loading;
  final HgTokens hg;
  const _StatusCard(
      {required this.status, required this.loading, required this.hg});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmt(DateTime d) {
    final local = d.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  static String _planLabel(ProPlan? p) => switch (p) {
        ProPlan.monthly => 'Monthly plan',
        ProPlan.yearly => 'Yearly plan',
        ProPlan.lifetime => 'Lifetime',
        null => 'Sustain Pro',
      };

  @override
  Widget build(BuildContext context) {
    final s = status;
    final String title;
    final String detail;
    final IconData icon;
    if (loading) {
      title = 'Sustain Pro';
      detail = 'Loading your plan…';
      icon = Icons.workspace_premium_rounded;
    } else if (s == null) {
      // Active (we only build this view when Pro), but the store withheld detail.
      title = 'Sustain Pro';
      detail = 'Your Pro access is active.';
      icon = Icons.workspace_premium_rounded;
    } else if (s.isLifetime) {
      title = 'Lifetime';
      detail = 'Yours forever — no renewal. Every Pro feature we add later is '
          'included automatically. Optional services like cloud backup are '
          'separate.';
      icon = Icons.all_inclusive_rounded;
    } else {
      title = _planLabel(s.plan);
      final when = s.expiration;
      if (when == null) {
        detail = 'Your plan is active.';
      } else if (s.willRenew) {
        detail = 'Renews on ${_fmt(when)}.';
      } else {
        detail = 'Cancelled — Pro stays active until ${_fmt(when)}.';
      }
      icon = s.willRenew
          ? Icons.autorenew_rounded
          : Icons.event_busy_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(HgSpacing.md),
      decoration: BoxDecoration(
        color: hg.accentMuted,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        border: Border.all(color: hg.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: hg.accent),
          const SizedBox(width: HgSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PLAN',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: hg.textMuted)),
                const SizedBox(height: 3),
                Text(title,
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary)),
                const SizedBox(height: 2),
                Text(detail,
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
    );
  }
}

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
