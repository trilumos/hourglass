import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/ui/insights_screen.dart';

SessionRecord rec(DateTime at, Duration focus,
        {SessionMode mode = SessionMode.flowBlock}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: '',
      plannedDuration: focus,
      recordedFocus: focus,
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: '',
      skinId: '',
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
      home: child,
    );

void main() {
  final now = DateTime(2026, 6, 18, 10);
  final sessions = [
    rec(DateTime(2026, 6, 18, 9), const Duration(minutes: 50)),
    rec(DateTime(2026, 6, 16, 20), const Duration(minutes: 25),
        mode: SessionMode.pomodoro),
  ];

  ProfileStats populatedStats() => ProfileStats(
        totalFocus: const Duration(minutes: 75),
        streak: 2,
        sessionsCompleted: 2,
        weekFocus: const Duration(minutes: 75),
        bestStreak: 4,
        avgSession: const Duration(minutes: 37),
        longestSession: const Duration(minutes: 50),
        totalSessions: 2,
        firstDate: DateTime(2026, 6, 1),
      );

  testWidgets('empty history shows the begin-your-first-block copy',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: _wrap(const InsightsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Begin your first block'), findsOneWidget);
  });

  testWidgets('populated history renders records and charts', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        profileStatsProvider.overrideWith((ref) async => populatedStats()),
        dailyFocusProvider.overrideWith((ref) async => {
              DateTime(2026, 6, 18): const DayStat(Duration(minutes: 50), 1),
            }),
        analyticsProvider.overrideWith((ref) async {
          final range = ref.watch(analyticsRangeProvider);
          return const AnalyticsCalculator().compute(range, now, sessions);
        }),
      ],
      child: _wrap(const InsightsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('RECORDS'), findsOneWidget);
    expect(find.text('FOCUS OVER TIME'), findsOneWidget);
    expect(find.text('BY MODE'), findsOneWidget);
  });

  testWidgets('switching the range to month does not throw', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      profileStatsProvider.overrideWith((ref) async => populatedStats()),
      dailyFocusProvider.overrideWith((ref) async => const <DateTime, DayStat>{}),
      analyticsProvider.overrideWith((ref) async {
        final range = ref.watch(analyticsRangeProvider);
        return const AnalyticsCalculator().compute(range, now, sessions);
      }),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const InsightsScreen()),
    ));
    await tester.pumpAndSettle();

    container.read(analyticsRangeProvider.notifier).set(AnalyticsRange.month);
    await tester.pumpAndSettle();

    expect(find.text('FOCUS OVER TIME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
