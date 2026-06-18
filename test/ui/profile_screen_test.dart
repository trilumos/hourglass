import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/profile_screen.dart';

void main() {
  testWidgets('profile hub nudges setup when no name is set', (tester) async {
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
        home: const ProfileScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set up your profile'), findsOneWidget);
  });
}
