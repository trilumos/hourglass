import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/domain/session_mode.dart';
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
        ],
        child: MaterialApp(
          theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
          home: SetupScreen(mode: mode),
        ),
      );

  testWidgets('shows intention, the stamina-suggested length, and begins',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.flowBlock));
    await tester.pump(); // resolve suggested length

    expect(find.text('INTENTION'), findsOneWidget);
    expect(find.text('LENGTH'), findsOneWidget);
    expect(find.text('Endless flow'), findsOneWidget);
    // Stamina-suggested 30-min chip is present (and pre-selected).
    expect(find.text('30 min'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Read chapter 4');
    await tester.tap(find.text('Flip to begin'));
    await tester.pumpAndSettle();

    // Navigated to the session destination carrying the config.
    expect(find.textContaining('Read chapter 4'), findsOneWidget);
    expect(find.textContaining('30 min'), findsOneWidget);
  });

  testWidgets('Pomodoro hides the endless-flow toggle and shows work/break',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness(SessionMode.pomodoro));
    await tester.pump();
    expect(find.text('Endless flow'), findsNothing);
    // Work-time stepper with an auto-derived break readout.
    expect(find.textContaining('25 min work · 5 min break'), findsOneWidget);
  });
}
