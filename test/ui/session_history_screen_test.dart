import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/session_history_screen.dart';

void main() {
  testWidgets('history shows the empty state with no sessions', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const SessionHistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('appear here'), findsOneWidget);
  });
}
