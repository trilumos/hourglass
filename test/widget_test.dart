import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/app.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to a screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) {
            final db = AppDatabase.memory();
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const HourglassApp(),
      ),
    );
    expect(find.byType(HourglassApp), findsOneWidget);
  });
}
