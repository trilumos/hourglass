import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_providers.dart';
import 'theme_controller.dart';
import 'tokens.dart';

/// The id of the theme currently being previewed ("try it on"), or null. IN
/// MEMORY ONLY — never persisted, so a relaunch is never stuck in preview. Set
/// by "Preview", cleared by "Exit" or when a purchase makes the theme owned.
class PreviewTheme extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String themeId) => state = themeId;
  void clear() => state = null;
}

final previewThemeProvider =
    NotifierProvider<PreviewTheme, String?>(PreviewTheme.new);

/// The single source of truth for the look the app + hourglass render, resolved
/// in priority order:
///   1. the PREVIEW theme, if previewing (regardless of ownership);
///   2. else the SELECTED theme, if owned;
///   3. else SAND (free fallback — covers never-bought, Pro lapsed, refund).
/// The stored themeId is kept even when unowned (so renewing restores the look);
/// it is simply not applied while unowned.
final activeThemeProvider = Provider<HgTheme>((ref) {
  final preview = ref.watch(previewThemeProvider);
  if (preview != null) return HgThemes.byId(preview);

  final selectedId = ref.watch(themeControllerProvider).themeId;
  final entitlements = ref.watch(entitlementsProvider);
  if (entitlements.ownsTheme(selectedId)) return HgThemes.byId(selectedId);

  return HgThemes.sand;
});
