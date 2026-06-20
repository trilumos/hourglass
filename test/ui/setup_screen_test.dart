import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/ui/session_screen.dart';
import 'package:hourglass/ui/setup_screen.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> phoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget harness(
    SessionMode mode, {
    StaminaInfo stamina = const StaminaInfo(true, Duration(minutes: 30)),
  }) =>
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          billingServiceProvider.overrideWith((ref) {
            final s = FakeBillingService();
            ref.onDispose(s.dispose);
            return s;
          }),
          staminaProvider.overrideWith((ref) async => stamina),
          breakAutoAdvanceProvider.overrideWith((ref) async => true),
          flowRunUntilEndedProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: SetupScreen(mode: mode),
        ),
      );

  testWidgets('Flow: intention, stamina-matched length, endless, begin',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.flowBlock));
    await tester.pump();

    expect(find.text('INTENTION'), findsOneWidget);
    expect(find.text('Length'), findsOneWidget);
    expect(find.text('Endless flow'), findsOneWidget);
    expect(find.text('Stamina · 30m'), findsOneWidget); // stamina-matched chip
    expect(find.text('30 min'), findsNothing); // replaced by the stamina anchor

    await tester.enterText(find.byType(TextField), 'Read chapter 4');
    await tester.tap(find.text('Begin'));
    // The live session animates indefinitely — push the route without settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SessionScreen), findsOneWidget);
  });

  testWidgets('Flow: the stamina chip is shown but locked until earned',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.flowBlock,
        stamina: const StaminaInfo(false, Duration(minutes: 25))));
    await tester.pump();

    // Shown but inaccessible: bare "Stamina" label (no "· Nm"), with a note.
    expect(find.text('Stamina'), findsOneWidget);
    expect(find.text('Stamina · 25m'), findsNothing);
    expect(find.textContaining('stamina sets after your first'),
        findsOneWidget);
    // A plain 25-min starting block is offered instead.
    expect(find.text('25 min'), findsOneWidget);
  });

  testWidgets('Pomodoro: total → focus time → block length, no endless',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.pomodoro));
    await tester.pump();

    // By duration (default): exact focus time → variable blocks (flowmodoro).
    expect(find.text('TOTAL TIME'), findsOneWidget);
    expect(find.text('By duration'), findsOneWidget);
    expect(find.text('By blocks'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('Blocks'), findsOneWidget);
    expect(find.text('Endless flow'), findsNothing);
    expect(find.text('Work / break per block'), findsNothing); // not in by-duration
    expect(find.textContaining('focus'), findsWidgets); // cadence subline

    // By blocks: fixed-length ratio chips + block count.
    await tester.tap(find.text('By blocks'));
    await tester.pump();
    expect(find.text('Focus blocks'), findsOneWidget);
    expect(find.text('Work / break per block'), findsOneWidget);
    expect(find.text('25/5'), findsOneWidget);
    expect(find.textContaining('rounds'), findsWidgets);
  });

  testWidgets('Custom: total → focus time → breaks (count/interval)',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.custom));
    await tester.pump();

    expect(find.text('TOTAL TIME'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('Break schedule'), findsOneWidget);
    expect(find.text('By count'), findsOneWidget);
    expect(find.text('By interval'), findsOneWidget);
    expect(find.text('Number of breaks'), findsOneWidget);
    expect(find.text('Break length'), findsOneWidget);
  });
}
