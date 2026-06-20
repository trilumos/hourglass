import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/edit_profile_screen.dart';
import 'package:hourglass/ui/widgets/primary_button.dart';

void main() {
  testWidgets('Save is disabled until a non-empty name is entered',
      (tester) async {
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
        home: const EditProfileScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(PrimaryButton, 'Save');
    expect(save, findsOneWidget);
    expect(tester.widget<PrimaryButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Deep  ');
    await tester.pump();
    expect(tester.widget<PrimaryButton>(save).onPressed, isNotNull);
  });
}
