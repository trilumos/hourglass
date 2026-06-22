import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_plan.dart';
import 'package:hourglass/session/ticker.dart';
import 'package:hourglass/ui/session_screen.dart';

/// Manually-advanced ticker for the session under test.
class FakeTicker implements Ticker {
  void Function(Duration delta)? _cb;
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) {
    _cb = onTick;
    running = true;
  }

  @override
  void stop() => running = false;

  void advance(Duration d) {
    if (running) _cb!(d);
  }
}

void main() {
  // wakelock_plus talks over a method channel that has no implementation in the
  // test host — answer it so initState's enable()/disable() don't throw.
  late SharedPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/wakelock'),
      (call) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  SessionConfig flowConfig() => SessionConfig(
        mode: SessionMode.flowBlock,
        plan: SessionPlan.flowBlock(const Duration(minutes: 25)),
        autoContinue: false,
        intention: 'Write the intro',
        soundscape: 'sand',
        skinId: 'classic',
      );

  Widget harness(AppDatabase db, FakeTicker ticker) => ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          billingServiceProvider.overrideWith((ref) {
            final s = FakeBillingService();
            ref.onDispose(s.dispose);
            return s;
          }),
          databaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: SessionScreen(
            config: flowConfig(),
            ticker: ticker,
            now: () => DateTime(2026, 6, 16, 9),
          ),
        ),
      );

  testWidgets('focus view shows the intention and a give-up affordance',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.memory();
    await tester.pumpWidget(harness(db, FakeTicker()));
    await tester.pump();

    expect(find.text('Write the intro'), findsOneWidget);
    expect(find.text('Give up'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('give up → confirm → completion shows the Focus Score',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.memory();
    final ticker = FakeTicker();
    await tester.pumpWidget(harness(db, ticker));
    await tester.pump();

    ticker.advance(const Duration(minutes: 10)); // a real, countable block
    await tester.pump();

    await tester.tap(find.text('Give up'));
    await tester.pump(); // open the sheet
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('End this block?'), findsOneWidget);

    await tester.tap(find.text('End block'));
    // Let the sheet close, the session finalize/persist, and the switch settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('SESSION SCORE'), findsOneWidget);
    expect(find.textContaining('focused'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('a free session shows Pause and the pauses-left count',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.memory();
    await tester.pumpWidget(harness(db, FakeTicker()));
    await tester.pump();

    // Free users get 3 disciplined pauses, surfaced on the control.
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('3 pauses left'), findsOneWidget);
  });
}
