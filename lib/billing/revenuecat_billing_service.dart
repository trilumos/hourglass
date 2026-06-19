import 'dart:async';

import '../domain/entitlements.dart';
import 'billing_service.dart';

/// Real RevenueCat-backed billing. Fully implemented in Task 5; this stub keeps
/// the app compiling and is never constructed while the key is empty.
class RevenueCatBillingService implements BillingService {
  final String apiKey;
  RevenueCatBillingService({required this.apiKey});

  final _controller = StreamController<Entitlements>.broadcast();
  final Entitlements _current = Entitlements.free;

  @override
  Future<void> init() async {}
  @override
  Entitlements get current => _current;
  @override
  Stream<Entitlements> entitlements() => _controller.stream;
  @override
  Future<ProOffering?> proOffering() async => null;
  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async =>
      PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.error;
  @override
  void dispose() => _controller.close();
}
