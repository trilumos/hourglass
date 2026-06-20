import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/theme_providers.dart';
import '../../app/tokens.dart';

/// A persistent bar shown while a locked theme is being previewed: "Previewing
/// X" + Get it (opens the Themes screen to buy / Get Pro) + Exit (clears the
/// preview). Renders nothing when not previewing. The preview is in-memory only,
/// so a relaunch clears it. Overlaid app-wide above the navigator (see app.dart).
class PreviewBar extends ConsumerWidget {
  /// Opens the place to buy the theme (the Themes screen). Provided by the app
  /// shell, which holds the root navigator.
  final VoidCallback onGetIt;
  const PreviewBar({super.key, required this.onGetIt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewId = ref.watch(previewThemeProvider);
    if (previewId == null) return const SizedBox.shrink();
    final name = HgThemes.byId(previewId).name;
    final hg = context.hg;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(HgSpacing.md),
        child: Material(
          color: hg.surfaceRaised,
          elevation: 6,
          borderRadius: BorderRadius.circular(HgRadius.lg),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                HgSpacing.lg, HgSpacing.sm, HgSpacing.sm, HgSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HgRadius.lg),
              border: Border.all(color: hg.hairline),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: HgSize.iconSm, color: hg.accent),
                const SizedBox(width: HgSpacing.sm),
                Expanded(
                  child: Text(
                    'Previewing $name',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontWeight: FontWeight.w600,
                      color: hg.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onGetIt,
                  child: Text(
                    'Get it',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontWeight: FontWeight.w600,
                      color: hg.accent,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(previewThemeProvider.notifier).clear(),
                  child: Text(
                    'Exit',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      color: hg.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
