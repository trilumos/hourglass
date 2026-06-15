import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/ui/widgets/adaptive_tagline.dart';
import 'package:hourglass/ui/widgets/typewriter_tagline.dart';

void main() {
  testWidgets('renders the typewriter tagline caption', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const Scaffold(body: AdaptiveTagline()),
      ),
    );
    await tester.pump();
    expect(find.byType(TypewriterTagline), findsOneWidget);
  });
}
