import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/ui/home_screen.dart';

void main() {
  final fixedNow = DateTime(2026, 6, 15, 10);

  ProviderScope harness(AppDatabase db) => ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          clockProvider.overrideWithValue(() => fixedNow),
        ],
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: const HomeScreen(),
        ),
      );

  testWidgets('renders Begin, a mode selector, and today\'s focus stat',
      (tester) async {
    final db = AppDatabase.memory();
    final repo = SessionRepository(db);
    await repo.insertSession(SessionRecord(
      id: 0,
      startedAt: fixedNow,
      mode: SessionMode.flowBlock,
      intention: 'x',
      plannedDuration: const Duration(minutes: 25),
      recordedFocus: const Duration(minutes: 25),
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
    ));

    await tester.pumpWidget(harness(db));
    // The hourglass animates forever, so pumpAndSettle would hang. Pump a few
    // frames to let the async stats future resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Begin'), findsOneWidget);
    // Mode selector shows the three modes.
    expect(find.text('Flow Block'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    // Today's focus reflects the seeded 25-minute completed session.
    expect(find.textContaining('25'), findsWidgets);
  });
}
