import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  test('starts free and emits pro after a successful purchase', () async {
    final svc = FakeBillingService(nextPurchase: PurchaseOutcome.success);
    addTearDown(svc.dispose);
    expect(svc.current.pro, isFalse);

    final emitted = <Entitlements>[];
    final sub = svc.entitlements().listen(emitted.add);

    const pkg = ProPackage(
        plan: ProPlan.monthly,
        priceString: r'$1.99',
        priceAmount: 1.99,
        currencyCode: 'USD',
        raw: 'x');
    final outcome = await svc.purchase(pkg);

    expect(outcome, PurchaseOutcome.success);
    expect(svc.current.pro, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(emitted.last.pro, isTrue);
    await sub.cancel();
  });

  test('cancelled purchase leaves entitlements free', () async {
    final svc = FakeBillingService(nextPurchase: PurchaseOutcome.cancelled);
    addTearDown(svc.dispose);
    final outcome = await svc.purchase(const ProPackage(
        plan: ProPlan.lifetime,
        priceString: r'$24.99',
        priceAmount: 24.99,
        currencyCode: 'USD',
        raw: 'x'));
    expect(outcome, PurchaseOutcome.cancelled);
    expect(svc.current.pro, isFalse);
  });

  test('restore with nothing returns nothingToRestore', () async {
    final svc = FakeBillingService(nextRestore: RestoreOutcome.nothingToRestore);
    addTearDown(svc.dispose);
    expect(await svc.restore(), RestoreOutcome.nothingToRestore);
    expect(svc.current.pro, isFalse);
  });
}
