import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/ui/session_screen.dart';
import 'package:hourglass/ui/setup_screen.dart';

void main() {
  Future<void> phoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget harness(SessionMode mode) => ProviderScope(
        overrides: [
          suggestedFlowLengthProvider
              .overrideWith((ref) async => const Duration(minutes: 30)),
          breakAutoAdvanceProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: SetupScreen(mode: mode),
        ),
      );

  testWidgets('Flow: intention, stamina-suggested length, endless, begin',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.flowBlock));
    await tester.pump();

    expect(find.text('INTENTION'), findsOneWidget);
    expect(find.text('Length'), findsOneWidget);
    expect(find.text('Endless flow'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget); // stamina-suggested chip

    await tester.enterText(find.byType(TextField), 'Read chapter 4');
    await tester.tap(find.text('Flip to begin'));
    // The live session animates indefinitely — push the route without settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SessionScreen), findsOneWidget);
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
