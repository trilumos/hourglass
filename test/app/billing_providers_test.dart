import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';

void main() {
  test('defaults to free, then reflects a billing emit', () async {
    final fake = FakeBillingService();
    final container = ProviderContainer(
        overrides: [billingServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    addTearDown(fake.dispose);

    expect(container.read(entitlementsProvider).pro, isFalse);

    // Simulate a confirmed purchase pushing through the stream.
    await fake.purchase(const ProPackage(
        plan: ProPlan.monthly,
        priceString: 'x',
        priceAmount: 1,
        currencyCode: 'USD',
        raw: 'x'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementsProvider).pro, isTrue);
  });
}
