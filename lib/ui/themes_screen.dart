import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/billing_providers.dart';
import '../app/theme.dart';
import '../app/theme_controller.dart';
import '../app/theme_providers.dart';
import '../app/tokens.dart';
import '../billing/billing_service.dart';
import '../hourglass/hourglass_view.dart';
import 'paywall_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// One short mood line per theme (the lineage from the spec, said plainly).
const Map<String, String> _moods = {
  'sand': 'Warm desert calm. The original.',
  'obsidian': 'Cool blue-black. Nocturnal and premium.',
  'sage': 'Quiet pine and forest green.',
  'rose': 'Soft, elegant warm rose.',
  'indigo': 'Deep sapphire jewel tones.',
  'dusk': 'Gentle lavender at twilight.',
  'tide': 'Deep luxe teal, like the ocean.',
  'noir': 'True black and warm gold.',
  'mocha': 'Dark espresso and caramel.',
  'aurora': 'Deep cosmos lit by shifting aurora light.',
};

/// Browse, preview, apply, and buy color themes. Owned themes apply instantly;
/// locked themes can be previewed live (whole app) and bought à la carte or via
/// Pro. Sand is always free/owned. Reached from Settings -> Display -> Themes.
class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});
  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  Map<String, ThemeProduct> _products = const {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(billingServiceProvider).themeProducts();
    if (!mounted) return;
    setState(() => _products = {for (final p in list) p.themeId: p});
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final entitlements = ref.watch(entitlementsProvider);
    final selectedId = ref.watch(themeControllerProvider).themeId;

    return Scaffold(
      backgroundColor: hg.background,
      body: ScreenBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HgSpacing.sm),
              // In-body header (no Material AppBar) — matches Settings / Profile.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
                child: Row(
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
                      'Themes',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HgSpacing.md),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(
                      HgSpacing.lg, 0, HgSpacing.lg, HgSpacing.xl),
                  crossAxisCount: 2,
                  mainAxisSpacing: HgSpacing.md,
                  crossAxisSpacing: HgSpacing.md,
                  childAspectRatio: 0.72,
                  children: [
                    for (final theme in HgThemes.all)
                      _ThemeTile(
                        theme: theme,
                        owned: entitlements.ownsTheme(theme.id),
                        // The applied look: the user's chosen theme, when owned.
                        active: theme.id == selectedId &&
                            entitlements.ownsTheme(theme.id),
                        product: _products[theme.id],
                        onTap: () => _openSheet(
                          theme,
                          owned: entitlements.ownsTheme(theme.id),
                          product: _products[theme.id],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(HgTheme theme, {required bool owned, ThemeProduct? product}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ThemeSheet(
        theme: theme,
        owned: owned,
        product: product,
        onApply: () {
          ref.read(themeControllerProvider.notifier).setTheme(theme.id);
          ref.read(previewThemeProvider.notifier).clear();
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
        },
        onPreview: () {
          ref.read(previewThemeProvider.notifier).set(theme.id);
          Navigator.of(context).pop();
        },
        onBuy: () async {
          final outcome =
              await ref.read(billingServiceProvider).purchaseTheme(theme.id);
          if (!mounted) return;
          if (outcome == PurchaseOutcome.success ||
              outcome == PurchaseOutcome.alreadyOwned) {
            // The entitlements stream unlocks it; apply + leave preview.
            ref.read(themeControllerProvider.notifier).setTheme(theme.id);
            ref.read(previewThemeProvider.notifier).clear();
          }
          if (mounted) Navigator.of(context).pop();
        },
        onGetPro: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        },
      ),
    );
  }
}

/// A theme's tokens for the brightness currently in effect.
HgTokens _tokensFor(HgTheme theme, Brightness b) =>
    b == Brightness.dark ? theme.dark : theme.light;

String _badge(bool owned, ThemeProduct? product) {
  if (owned) return 'Owned';
  if (product != null) return product.priceString;
  return 'In Pro';
}

class _ThemeTile extends StatelessWidget {
  final HgTheme theme;
  final bool owned;
  final bool active;
  final ThemeProduct? product;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.owned,
    required this.active,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final t = _tokensFor(theme, brightness);
    final isFlagship = theme.id == 'aurora';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(HgRadius.lg),
          border: Border.all(
            color: active ? t.accent : t.hairline,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(HgSpacing.md),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A small live-coloured hourglass over the theme's own backdrop.
              Expanded(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.background,
                      borderRadius: BorderRadius.circular(HgRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: HgSpacing.lg, vertical: HgSpacing.sm),
                      child: SizedBox(
                        width: 47,
                        height: 90,
                        child: HourglassView(
                          progress: 0.5,
                          animate: false,
                          skin: theme.skinFor(brightness),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HgSpacing.sm),
              Row(
                children: [
                  _Swatch(t.background),
                  _Swatch(t.surfaceRaised),
                  _Swatch(t.accent),
                  const Spacer(),
                  if (active)
                    Icon(Icons.check_circle, size: HgSize.iconSm, color: t.accent),
                ],
              ),
              const SizedBox(height: HgSpacing.sm),
              Text(
                theme.name,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _badge(owned, product),
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 12,
                  color: owned ? t.accent : t.textMuted,
                ),
              ),
                ],
              ),
            ),
            if (isFlagship)
              Positioned(
                top: HgSpacing.sm,
                right: HgSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(HgRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 11, color: t.onAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Flagship',
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: t.onAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch(this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x22000000)),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  final HgTheme theme;
  final bool owned;
  final ThemeProduct? product;
  final VoidCallback onApply;
  final VoidCallback onPreview;
  final VoidCallback onBuy;
  final VoidCallback onGetPro;
  const _ThemeSheet({
    required this.theme,
    required this.owned,
    required this.product,
    required this.onApply,
    required this.onPreview,
    required this.onBuy,
    required this.onGetPro,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final t = _tokensFor(theme, brightness);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(HgRadius.lg)),
        border: Border.all(color: t.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(
          HgSpacing.lg, HgSpacing.md, HgSpacing.lg, HgSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: HgSpacing.md),
                decoration: BoxDecoration(
                  color: t.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.background,
                borderRadius: BorderRadius.circular(HgRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(HgSpacing.lg),
                child: Center(
                  // Explicit 0.52 ratio box (matches HourglassView) so the
                  // stretched sheet column can't squash it wide.
                  child: SizedBox(
                    width: 83,
                    height: 160,
                    child: HourglassView(
                      progress: 0.5,
                      animate: false,
                      skin: theme.skinFor(brightness),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: HgSpacing.lg),
            Text(
              theme.name,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: HgSpacing.xs),
            Text(
              _moods[theme.id] ?? '',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: HgSpacing.lg),
            if (owned)
              _SheetTheme(t, child: PrimaryButton(label: 'Apply', onPressed: onApply))
            else ...[
              _SheetTheme(t, child: PrimaryButton(label: 'Preview', onPressed: onPreview)),
              const SizedBox(height: HgSpacing.sm),
              if (product != null) ...[
                _QuietButton(
                  label: 'Buy ${product!.priceString}',
                  color: t.accent,
                  onPressed: onBuy,
                ),
                const SizedBox(height: HgSpacing.sm),
              ],
              _QuietButton(
                label: 'Get Pro',
                color: t.textSecondary,
                onPressed: onGetPro,
              ),
              const SizedBox(height: HgSpacing.sm),
              Text(
                'Pro unlocks every theme while active. Pro Lifetime keeps them '
                'forever.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 12,
                  color: t.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps a child in the previewed theme's tokens so [PrimaryButton] (which reads
/// `context.hg`) paints in that theme, not the app's current one.
class _SheetTheme extends StatelessWidget {
  final HgTokens tokens;
  final Widget child;
  const _SheetTheme(this.tokens, {required this.child});
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(extensions: <ThemeExtension<dynamic>>[tokens]),
      child: child,
    );
  }
}

class _QuietButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _QuietButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HgRadius.md),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: HgFont.sans,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
