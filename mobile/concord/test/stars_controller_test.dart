import 'package:concord/api/api.dart';
import 'package:concord/providers/api_providers.dart';
import 'package:concord/providers/stars_providers.dart';
import 'package:concord/utils/idempotency_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes by subclassing (this project's existing test convention - see
/// `test/billing_controller_test.dart` and `test/widget_test.dart`) rather than pulling in a
/// mocking package.
class _FakeStarsService extends StarsService {
  _FakeStarsService({
    this.walletResult,
    this.configResult,
    this.loadError,
    this.transferResult,
    this.transferError,
    this.trialResult,
    this.trialError,
  }) : super(ApiClient(tokenStorage: TokenStorage()));

  final StarWalletResponse? walletResult;
  final StarsConfigResponse? configResult;
  final ApiException? loadError;
  final TransferStarsResponse? transferResult;
  final ApiException? transferError;
  final ActivatePremiumTrialResponse? trialResult;
  final ApiException? trialError;

  var getWalletCallCount = 0;
  String? lastIdempotencyKey;

  @override
  Future<StarWalletResponse> getWallet() async {
    getWalletCallCount++;
    if (loadError != null) throw loadError!;
    return walletResult!;
  }

  @override
  Future<StarsConfigResponse> getConfig() async {
    if (loadError != null) throw loadError!;
    return configResult!;
  }

  @override
  Future<TransferStarsResponse> transfer({
    required String recipientUserId,
    required int amount,
    required String idempotencyKey,
  }) async {
    lastIdempotencyKey = idempotencyKey;
    if (transferError != null) throw transferError!;
    return transferResult!;
  }

  @override
  Future<ActivatePremiumTrialResponse> activatePremiumTrial(String idempotencyKey) async {
    lastIdempotencyKey = idempotencyKey;
    if (trialError != null) throw trialError!;
    return trialResult!;
  }
}

StarWalletResponse _wallet({int balance = 120, bool trialActive = false, bool premium = false}) =>
    StarWalletResponse.fromJson({
      'Balance': balance,
      'PremiumTrialActive': trialActive,
      'PremiumTrialExpiresAt': null,
      'HasActivePremium': premium,
    });

StarsConfigResponse _config() => StarsConfigResponse.fromJson({
      'ChatRewardAmount': 2,
      'ChatRewardCooldownSeconds': 30,
      'ChatRewardDailyCap': 50,
      'PremiumTrialCostStars': 500,
      'PremiumTrialDurationDays': 14,
      'Packages': [
        {'Id': 'stars_100', 'Stars': 100, 'PriceAmount': 0.99, 'Currency': 'usd'},
      ],
    });

ProviderContainer _containerFor(_FakeStarsService service) {
  final container = ProviderContainer(overrides: [starsServiceProvider.overrideWithValue(service)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('StarsController', () {
    test('load() transitions isLoading -> loaded with the fetched wallet and config', () async {
      final container = _containerFor(
        _FakeStarsService(walletResult: _wallet(balance: 250), configResult: _config()),
      );

      // The constructor kicks off `load()` itself; the initial synchronous state is the loading one.
      expect(container.read(starsControllerProvider).isLoading, isTrue);

      await container.read(starsControllerProvider.notifier).load();

      final state = container.read(starsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.loadError, isNull);
      expect(state.balance, 250);
      expect(state.config?.premiumTrialCostStars, 500);
      expect(state.config?.packages.single.id, 'stars_100');
    });

    test('load() transitions isLoading -> loadError on ApiException', () async {
      final container = _containerFor(_FakeStarsService(loadError: const ApiException(500, 'boom')));

      await container.read(starsControllerProvider.notifier).load();

      final state = container.read(starsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.loadError?.message, 'boom');
      expect(state.wallet, isNull);
    });

    test('transfer() applies the balance from the response and reports no failure', () async {
      final service = _FakeStarsService(
        walletResult: _wallet(balance: 120),
        configResult: _config(),
        transferResult: TransferStarsResponse.fromJson({'Balance': 70}),
      );
      final container = _containerFor(service);
      await container.read(starsControllerProvider.notifier).load();

      final failure = await container.read(starsControllerProvider.notifier).transfer(
            recipientUserId: 'friend-1',
            amount: 50,
            idempotencyKey: 'key-1',
          );

      expect(failure, isNull);
      expect(service.lastIdempotencyKey, 'key-1');
      expect(container.read(starsControllerProvider).balance, 70);
      expect(container.read(starsControllerProvider).transferInFlight, isFalse);
    });

    test('transfer() returns the ApiException and leaves the balance untouched', () async {
      final service = _FakeStarsService(
        walletResult: _wallet(balance: 120),
        configResult: _config(),
        transferError: const ApiException(403, 'Not friends'),
      );
      final container = _containerFor(service);
      await container.read(starsControllerProvider.notifier).load();

      final failure = await container.read(starsControllerProvider.notifier).transfer(
            recipientUserId: 'stranger',
            amount: 10,
            idempotencyKey: 'key-2',
          );

      expect(failure?.statusCode, 403);
      expect(container.read(starsControllerProvider).balance, 120);
      expect(container.read(starsControllerProvider).transferInFlight, isFalse);
    });

    test('activatePremiumTrial() marks the trial active and debits the balance', () async {
      final service = _FakeStarsService(
        walletResult: _wallet(balance: 600),
        configResult: _config(),
        trialResult: ActivatePremiumTrialResponse.fromJson({
          'Balance': 100,
          'PremiumTrialExpiresAt': '2026-10-01T10:00:00Z',
        }),
      );
      final container = _containerFor(service);
      await container.read(starsControllerProvider.notifier).load();

      final failure = await container.read(starsControllerProvider.notifier).activatePremiumTrial('key-3');

      final state = container.read(starsControllerProvider);
      expect(failure, isNull);
      expect(state.balance, 100);
      expect(state.wallet?.premiumTrialActive, isTrue);
      expect(state.wallet?.hasActivePremium, isTrue);
      expect(state.wallet?.premiumTrialExpiresAt, DateTime.parse('2026-10-01T10:00:00Z'));
    });

    test('activatePremiumTrial() surfaces a conflict without touching the wallet', () async {
      final service = _FakeStarsService(
        walletResult: _wallet(balance: 600),
        configResult: _config(),
        trialError: const ApiException(409, 'Trial already active'),
      );
      final container = _containerFor(service);
      await container.read(starsControllerProvider.notifier).load();

      final failure = await container.read(starsControllerProvider.notifier).activatePremiumTrial('key-4');

      expect(failure?.statusCode, 409);
      expect(container.read(starsControllerProvider).balance, 600);
      expect(container.read(starsControllerProvider).trialInFlight, isFalse);
    });

    test('refreshAfterResume() is a no-op when no Stripe flow is pending', () async {
      final service = _FakeStarsService(walletResult: _wallet(), configResult: _config());
      final container = _containerFor(service);
      await container.read(starsControllerProvider.notifier).load();
      final callsAfterLoad = service.getWalletCallCount;

      await container.read(starsControllerProvider.notifier).refreshAfterResume();

      expect(service.getWalletCallCount, callsAfterLoad);
      expect(container.read(starsControllerProvider).pendingStripeFlow, isFalse);
    });
  });

  group('newIdempotencyKey', () {
    test('produces a distinct, well-formed v4 UUID per call', () {
      final keys = List.generate(100, (_) => newIdempotencyKey());

      expect(keys.toSet().length, 100);
      for (final key in keys) {
        expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(key),
          isTrue,
          reason: '$key is not a v4 UUID',
        );
      }
    });
  });
}
