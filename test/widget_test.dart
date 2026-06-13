import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/app.dart';

void main() {
  testWidgets('app boots to a screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HourglassApp()));
    expect(find.byType(HourglassApp), findsOneWidget);
  });
}
