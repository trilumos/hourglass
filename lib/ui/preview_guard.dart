import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../app/theme_providers.dart';
import '../app/tokens.dart';

/// While a theme is being PREVIEWED, the app is in a purely cosmetic "try it on"
/// state and no persistent data may change. Call this at the top of any action
/// that mutates user state (clear data, edit profile, session settings, ...). If
/// a preview is active it shows a popup and returns true, so the caller aborts.
///
/// [action] is a short verb phrase, e.g. 'clear data' -> "Cannot clear data
/// during preview".
bool blockedByPreview(BuildContext context, WidgetRef ref, String action) {
  if (ref.read(previewThemeProvider) == null) return false;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final hg = ctx.hg;
      return AlertDialog(
        backgroundColor: hg.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HgRadius.lg),
        ),
        content: Text(
          'Cannot $action during preview',
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 15,
            color: hg.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(previewThemeProvider.notifier).clear();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Exit preview',
              style: TextStyle(fontFamily: HgFont.sans, color: hg.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: HgFont.sans, color: hg.textSecondary),
            ),
          ),
        ],
      );
    },
  );
  return true;
}
