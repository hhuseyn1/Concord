import 'package:concord/api/api.dart';
import 'package:concord/providers/api_providers.dart';
import 'package:concord/providers/billing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes by subclassing (matching this project's existing test convention - see
/// `test/widget_test.dart`'s `_FakeTokenStorage`) rather than pulling in a mocking package.
class _FakeBillingService extends BillingService {
  _FakeBillingService({this.subscriptionResult, this.subscriptionError}) : super(ApiClient(tokenStorage: TokenStorage()));

  final SubscriptionResponse? subscriptionResult;
  final ApiException? subscriptionError;
  var getSubscriptionCallCount = 0;

  @override
  Future<SubscriptionResponse> getSubscription() async {
    getSubscriptionCallCount++;
    if (subscriptionError != null) throw subscriptionError!;
    return subscriptionResult!;
  }
}

SubscriptionResponse _none() => SubscriptionResponse.fromJson({
      'Status': 'None',
      'CurrentPeriodEnd': null,
      'CancelAtPeriodEnd': false,
    });

SubscriptionResponse _active() => SubscriptionResponse.fromJson({
      'Status': 'Active',
      'CurrentPeriodEnd': '2026-10-13T06:05:54Z',
      'CancelAtPeriodEnd': false,
    });

void main() {
  group('BillingController', () {
    test('load() transitions isLoading -> loaded with the fetched subscription', () async {
      final container = ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(_FakeBillingService(subscriptionResult: _none())),
        ],
      );
      addTearDown(container.dispose);

      // The constructor kicks off `load()` itself; the initial synchronous state is the loading one.
      expect(container.read(billingControllerProvider).isLoading, isTrue);

      await container.read(billingControllerProvider.notifier).load();

      final state = container.read(billingControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.loadError, isNull);
      expect(state.subscription?.status, SubscriptionStatus.none);
    });

    test('load() transitions isLoading -> loadError on ApiException', () async {
      final container = ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(
            _FakeBillingService(subscriptionError: const ApiException(500, 'boom')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(billingControllerProvider.notifier).load();

      final state = container.read(billingControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.loadError, 'boom');
      expect(state.subscription, isNull);
    });

    test('refreshAfterResume() is a no-op when no Stripe flow is pending', () async {
      final service = _FakeBillingService(subscriptionResult: _active());
      final container = ProviderContainer(overrides: [billingServiceProvider.overrideWithValue(service)]);
      addTearDown(container.dispose);

      await container.read(billingControllerProvider.notifier).load();
      final callsAfterLoad = service.getSubscriptionCallCount;

      await container.read(billingControllerProvider.notifier).refreshAfterResume();

      expect(service.getSubscriptionCallCount, callsAfterLoad);
      expect(container.read(billingControllerProvider).pendingStripeFlow, isFalse);
    });
  });
}
