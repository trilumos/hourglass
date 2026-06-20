import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/ui/preview_guard.dart';

void main() {
  Future<bool?> tapGuarded(WidgetTester tester, ProviderContainer c) async {
    bool? proceeded;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () {
                  if (blockedByPreview(context, ref, 'clear data')) {
                    proceeded = false;
                    return;
                  }
                  proceeded = true;
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return proceeded;
  }

  testWidgets('not previewing: action proceeds, no popup', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final proceeded = await tapGuarded(tester, c);
    expect(proceeded, isTrue);
    expect(find.text('Cannot clear data during preview'), findsNothing);
  });

  testWidgets('previewing: action blocked, popup shown with Exit preview',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(previewThemeProvider.notifier).set('obsidian');

    final proceeded = await tapGuarded(tester, c);
    expect(proceeded, isFalse);
    expect(find.text('Cannot clear data during preview'), findsOneWidget);

    // "Exit preview" clears the preview and dismisses.
    await tester.tap(find.text('Exit preview'));
    await tester.pumpAndSettle();
    expect(c.read(previewThemeProvider), isNull);
  });
}
