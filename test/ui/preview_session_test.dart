import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_plan.dart';
import 'package:hourglass/session/ticker.dart';
import 'package:hourglass/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Inert ticker: the session clock never advances on its own, so the only thing
/// that ends this run is the preview cap (a real Timer, advanced by pump).
class FakeTicker implements Ticker {
  @override
  void start(void Function(Duration delta) onTick) {}
  @override
  void stop() {}
}

void main() {
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
        intention: 'Preview',
        soundscape: 'sand',
        skinId: 'classic',
      );

  ProviderContainer makeContainer(AppDatabase db) => ProviderContainer(overrides: [
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
      ]);

  Widget previewApp(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: SessionScreen(
            config: flowConfig(),
            ticker: FakeTicker(),
            now: () => DateTime(2026, 6, 16, 9),
            previewMode: true,
          ),
        ),
      );

  testWidgets('a preview session caps at ~10s, persists nothing, and prompts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = AppDatabase.memory();
    final container = makeContainer(db);
    addTearDown(container.dispose);

    // Stand in a live preview of a locked theme.
    container.read(previewThemeProvider.notifier).set('obsidian');

    await tester.pumpWidget(previewApp(container));
    await tester.pump();

    // Before the cap, no prompt yet.
    expect(find.text('Exit preview'), findsNothing);

    // Advance past the ~10s cap → the preview ends with the buy/exit prompt.
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();

    expect(find.text('Enjoying Obsidian?'), findsOneWidget);
    expect(find.text('Get it'), findsOneWidget);
    expect(find.text('Exit preview'), findsOneWidget);

    // The core guarantee: a preview records NOTHING.
    final sessions = await container.read(sessionRepositoryProvider).allSessions();
    expect(sessions, isEmpty);
  });

  testWidgets('giving up during a preview also shows the prompt, persists nothing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = AppDatabase.memory();
    final container = makeContainer(db);
    addTearDown(container.dispose);
    container.read(previewThemeProvider.notifier).set('obsidian');

    await tester.pumpWidget(previewApp(container));
    await tester.pump();

    // Give up before the cap.
    await tester.tap(find.text('Give up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('End block'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    // The preview prompt, NOT the real completion/score screen.
    expect(find.text('Enjoying Obsidian?'), findsOneWidget);
    expect(find.text('SESSION SCORE'), findsNothing);

    final sessions = await container.read(sessionRepositoryProvider).allSessions();
    expect(sessions, isEmpty);
  });
}
