// ── Sustain screenshot / store-preview build ────────────────────────────────
// Everything for the preview build lives in THIS folder (lib/preview/). It is
// never imported by the real app (lib/main.dart is untouched) — it only reuses
// the real screens/providers so the screenshots show the genuine UI.
//
// What it does:
//  • in-memory DB seeded with realistic placeholder data, so every screen —
//    Home, Insights, Focus Score, History, Profile — looks alive, and onboarding
//    is auto-skipped (the migration guard sees existing data),
//  • fake billing with USD prices (Pro $4.99/$29.99/$59.99; themes $1.99,
//    Aurora $3.99) so the paywall + theme sheets show real prices,
//  • Pro toggled from Settings → "Dev: unlock Pro" (build in debug) so you can
//    capture BOTH the free state (paywall/prices, Insights upsells) and the Pro
//    state (full Insights, Stamina, Avg).
//
// Build it (debug, so the Pro toggle is available):
//   flutter run                -t lib/preview/preview_main.dart
//   flutter build apk --debug  -t lib/preview/preview_main.dart
//
// No real purchases, accounts, or network. Nothing here affects the real build.

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../app/app.dart';
import '../app/billing_providers.dart';
import '../app/providers.dart';
import '../app/theme_controller.dart' show sharedPrefsProvider;
import '../billing/billing_config.dart';
import '../billing/billing_service.dart';
import '../billing/fake_billing_service.dart';
import '../data/app_database.dart';
import '../domain/entitlements.dart';
import '../domain/session_mode.dart';
import '../session/ticker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.memory();
  await _seedDemoData(db);

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        billingServiceProvider.overrideWithValue(_previewBilling()),
        // Sessions fast-forward to ~10 min for clean paused/end-screen captures.
        sessionTickerFactoryProvider.overrideWithValue(_PreviewTicker.new),
      ],
      child: const HourglassApp(),
    ),
  );
}

/// A fake billing service with the locked USD prices, so the money screens read
/// correctly in screenshots. Starts Free (prices visible); flip Pro from
/// Settings → "Dev: unlock Pro" to capture the Pro screens.
BillingService _previewBilling() {
  ProPackage pkg(ProPlan plan, String price, double amount) => ProPackage(
        plan: plan,
        priceString: price,
        priceAmount: amount,
        currencyCode: 'USD',
        raw: 'preview',
      );
  return FakeBillingService(
    initial: Entitlements.free,
    offering: ProOffering([
      pkg(ProPlan.yearly, r'$29.99', 29.99),
      pkg(ProPlan.monthly, r'$4.99', 4.99),
      pkg(ProPlan.lifetime, r'$59.99', 59.99),
    ]),
    themeProductList: [
      for (final id in kCatalogThemeIds)
        ThemeProduct(
          themeId: id,
          priceString: id == 'aurora' ? r'$3.99' : r'$1.99',
          raw: 'preview',
        ),
    ],
  );
}

/// Inserts a believable, active-user history so every stat/chart/heatmap renders
/// with real-looking content. Deterministic (fixed seed) so screenshots repeat.
Future<void> _seedDemoData(AppDatabase db) async {
  const uuid = Uuid();
  final now = DateTime.now();

  await db.into(db.profile).insert(ProfileCompanion.insert(
        uuid: uuid.v4(),
        name: const Value('Alex Rivera'),
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
      ));

  const intentions = [
    'Deep work',
    'Study session',
    'Writing',
    'Reading',
    'Coding sprint',
    'Exam prep',
  ];
  // Flow blocks skew longer + finish more often, so the Focus Score, Stamina,
  // and averages read strong (never 0) in screenshots.
  const flowPlans = [45, 50, 60, 75, 90];
  const otherPlans = [25, 30, 50];
  final rnd = Random(42);
  final rows = <SessionsCompanion>[];

  for (var day = 40; day >= 0; day--) {
    // The last ~13 days are always active (a clean current streak + dense recent
    // heatmap); older days have occasional rest days for a natural pattern.
    final restDay = day > 13 && rnd.nextInt(10) < 3;
    if (restDay) continue;

    final count = 1 + (rnd.nextInt(10) < 4 ? 1 : 0); // mostly 1, sometimes 2
    for (var s = 0; s < count; s++) {
      final hour = 8 + rnd.nextInt(12); // 8:00–19:59
      final started = DateTime(now.year, now.month, now.day, hour, rnd.nextInt(60))
          .subtract(Duration(days: day));
      final roll = rnd.nextInt(10);
      final mode = roll < 6
          ? SessionMode.flowBlock
          : (roll < 8 ? SessionMode.pomodoro : SessionMode.custom);
      final isFlow = mode == SessionMode.flowBlock;
      final plans = isFlow ? flowPlans : otherPlans;
      final planMin = plans[rnd.nextInt(plans.length)];
      final completed = rnd.nextInt(10) < (isFlow ? 9 : 8); // flow finishes more
      final recordedMin = completed
          ? planMin
          : (planMin * (0.55 + rnd.nextDouble() * 0.35)).round();
      rows.add(SessionsCompanion.insert(
        startedAt: started,
        mode: mode,
        intention: Value(intentions[rnd.nextInt(intentions.length)]),
        plannedSeconds: planMin * 60,
        recordedSeconds: recordedMin * 60,
        completed: Value(completed),
        abandoned: Value(!completed),
        uuid: Value(uuid.v4()),
        updatedAt: Value(started),
      ));
    }
  }

  await db.batch((b) => b.insertAll(db.sessions, rows));
}

/// Fast-forwards a session so screenshots are quick: jumps to [jump] on the first
/// start (so the screen lands at ~10 min with the hourglass filled accordingly),
/// then advances quickly so it reaches the end in a few seconds. You have ~700ms
/// after the jump to tap Pause for a clean "paused at 10:00" capture; let it run
/// for the end screen (which then shows a real, non-zero session score). The real
/// app uses the per-second [PeriodicTicker].
class _PreviewTicker implements Ticker {
  final Duration jump;
  Timer? _timer;
  bool _jumped = false;
  _PreviewTicker({this.jump = const Duration(minutes: 10)});

  @override
  void start(void Function(Duration delta) onTick) {
    _timer?.cancel();
    if (!_jumped) {
      _jumped = true;
      // After start() returns (avoid reentrancy during session init).
      Future.microtask(() => onTick(jump));
    }
    _timer = Timer.periodic(const Duration(milliseconds: 700),
        (_) => onTick(const Duration(seconds: 30)));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
