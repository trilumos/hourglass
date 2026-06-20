import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/domain/personal_bests.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/ui/insights_copy.dart';
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

  InsightsExtras extrasFor(AnalyticsRange range) {
    const calc = AnalyticsCalculator();
    final inRange = calc.sessionsInRange(range, now, sessions);
    return InsightsExtras(
      scoreTrend: calc.focusScoreTrend(range, now, sessions),
      staminaGrowth: calc.staminaGrowth(range, now, sessions),
      peakWindow: calc.peakWindowCaption(inRange),
      followThrough: calc.followThrough(range, now, sessions),
      bests: const PersonalBestsCalculator().compute(sessions),
    );
  }

  /// A tall, narrow viewport so the whole scroll body builds for `find`.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 7000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('empty history shows the begin-your-first-block copy',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        billingServiceProvider.overrideWithValue(FakeBillingService()),
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

  testWidgets('populated history renders records, charts, and Pro depth band',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        billingServiceProvider.overrideWithValue(FakeBillingService(
            initial: const Entitlements(pro: true, ownedThemeIds: {'sand'}))),
        profileStatsProvider.overrideWith((ref) async => populatedStats()),
        dailyFocusProvider.overrideWith((ref) async => {
              DateTime(2026, 6, 18): const DayStat(Duration(minutes: 50), 1),
            }),
        analyticsProvider.overrideWith((ref) async {
          final range = ref.watch(analyticsRangeProvider);
          return const AnalyticsCalculator().compute(range, now, sessions);
        }),
        insightsExtrasProvider.overrideWith((ref) async {
          final range = ref.watch(analyticsRangeProvider);
          return extrasFor(range);
        }),
      ],
      child: _wrap(const InsightsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('RECORDS'), findsOneWidget);
    expect(find.text('FOCUS SCORE'), findsOneWidget);
    expect(find.text('FOCUS STAMINA'), findsOneWidget);
    expect(find.text('FOCUS OVER TIME'), findsOneWidget);
    expect(find.text('FOLLOW-THROUGH'), findsOneWidget);
    expect(find.text('BY MODE'), findsOneWidget);
    expect(find.text('PERSONAL BESTS'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
  });

  testWidgets('trend sections show honest empty copy with no scored sessions',
      (tester) async {
    tallView(tester);
    // Pomodoro-only history: there are focused sessions (so we reach the depth
    // band) but no Flow → no Focus Score / Stamina series.
    final pomoOnly = [
      rec(DateTime(2026, 6, 18, 9), const Duration(minutes: 25),
          mode: SessionMode.pomodoro),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        billingServiceProvider.overrideWithValue(FakeBillingService(
            initial: const Entitlements(pro: true, ownedThemeIds: {'sand'}))),
        profileStatsProvider.overrideWith((ref) async => populatedStats()),
        dailyFocusProvider.overrideWith((ref) async => const {}),
        analyticsProvider.overrideWith((ref) async {
          final range = ref.watch(analyticsRangeProvider);
          return const AnalyticsCalculator().compute(range, now, pomoOnly);
        }),
        insightsExtrasProvider.overrideWith((ref) async {
          final range = ref.watch(analyticsRangeProvider);
          const calc = AnalyticsCalculator();
          final inRange = calc.sessionsInRange(range, now, pomoOnly);
          return InsightsExtras(
            scoreTrend: calc.focusScoreTrend(range, now, pomoOnly),
            staminaGrowth: calc.staminaGrowth(range, now, pomoOnly),
            peakWindow: calc.peakWindowCaption(inRange),
            followThrough: calc.followThrough(range, now, pomoOnly),
            bests: const PersonalBestsCalculator().compute(pomoOnly),
          );
        }),
      ],
      child: _wrap(const InsightsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text(InsightsCopy.scoreEmpty), findsOneWidget);
    expect(find.text(InsightsCopy.staminaEmpty), findsOneWidget);
  });

  testWidgets('switching the range to month does not throw', (tester) async {
    tallView(tester);
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      billingServiceProvider.overrideWithValue(FakeBillingService(
          initial: const Entitlements(pro: true, ownedThemeIds: {'sand'}))),
      profileStatsProvider.overrideWith((ref) async => populatedStats()),
      dailyFocusProvider.overrideWith((ref) async => const <DateTime, DayStat>{}),
      analyticsProvider.overrideWith((ref) async {
        final range = ref.watch(analyticsRangeProvider);
        return const AnalyticsCalculator().compute(range, now, sessions);
      }),
      insightsExtrasProvider.overrideWith((ref) async {
        final range = ref.watch(analyticsRangeProvider);
        return extrasFor(range);
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
