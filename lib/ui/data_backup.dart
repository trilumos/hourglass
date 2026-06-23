import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart' show openFile, XTypeGroup;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/providers.dart';
import '../data/backup_service.dart';

/// Export all on-device data to a JSON file and open the share sheet so the user
/// saves it themselves (Drive, Files, email...). Their backup, their storage.
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final data = await ref.read(backupServiceProvider).exportData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final now = ref.read(clockProvider)();
    final stamp = '${now.year}-${_pad2(now.month)}-${_pad2(now.day)}';
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'sustain-backup-$stamp.json'));
    await file.writeAsString(json);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Sustain backup',
      text: 'My Sustain backup ($stamp). Keep it safe — restore it on a new '
          'phone from Settings > Your data.',
    ));
  } catch (_) {
    messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't create a backup right now.")));
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Confirm, let the user pick a backup file, and restore it. Sessions MERGE
/// (nothing is deleted); profile + settings are replaced. Refreshes the app.
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore from a backup?'),
      content: const Text(
        'Pick a Sustain backup file. Your sessions are merged in (nothing is '
        'deleted), and your profile and settings are replaced by the backup.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose file')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  // The app-level container + navigator survive leaving this screen, so we can
  // refresh AFTER returning to Home (a fragile in-place rebuild of the screen
  // that launched restore is what greyed the app out before).
  final container = ProviderScope.containerOf(context, listen: false);
  final navigator = Navigator.of(context);
  XFile? file;
  try {
    file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Sustain backup', extensions: ['json']),
    ]);
  } catch (_) {
    messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open the file picker.")));
    return;
  }
  if (file == null) return; // cancelled

  try {
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    final added = await container.read(backupServiceProvider).importData(data);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup restored'),
        content: Text(added == 0
            ? 'Everything in this backup was already here.'
            : 'Added $added session${added == 1 ? '' : 's'}. Your profile and '
                'settings are updated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
    // Return to a fresh Home, THEN re-read the restored data through the app
    // container (which outlives this screen) — no in-place cascade to grey out.
    navigator.popUntil((r) => r.isFirst);
    _refreshAfterRestore(container);
  } on BackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
        content: Text("That file couldn't be read as a backup.")));
  }
}

void _refreshAfterRestore(ProviderContainer c) {
  // The theme lives in SharedPreferences (not in the backup), so it isn't
  // refreshed here. Everything below reads the DB the restore just wrote.
  c.invalidate(profileProvider);
  c.invalidate(homeStatsProvider);
  c.invalidate(focusScoreProvider);
  c.invalidate(profileStatsProvider);
  c.invalidate(sessionHistoryProvider);
  c.invalidate(dailyFocusProvider);
  c.invalidate(staminaProvider);
  c.invalidate(breakAutoAdvanceProvider);
  c.invalidate(flowRunUntilEndedProvider);
}
