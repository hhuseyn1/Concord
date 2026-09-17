import 'api_client.dart';
import 'models/paged_result.dart';
import 'models/star_transaction_response.dart';
import 'models/star_wallet_response.dart';
import 'models/stars_action_responses.dart';
import 'models/stars_config_response.dart';

/// The Stars virtual-currency API (`Api/V1.0/Stars`, every endpoint authorized).
/// Mirrors [BillingService]'s shape - the package-purchase flow is the same
/// Stripe-hosted-checkout arrangement as the Premium subscription one.
class StarsService {
  StarsService(this._client);

  final ApiClient _client;

  Future<StarsConfigResponse> getConfig() async {
    final data = await _client.get('/Stars/Config');
    return StarsConfigResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<StarWalletResponse> getWallet() async {
    final data = await _client.get('/Stars/Wallet');
    return StarWalletResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PagedResult<StarTransactionResponse>> getTransactions({int page = 1, int pageSize = 20}) async {
    final data = await _client.get('/Stars/Transactions', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, StarTransactionResponse.fromJson);
  }

  /// [idempotencyKey] is generated once per user attempt and reused verbatim
  /// across retries of that same attempt, so a double-tap or a retried request
  /// short-circuits server-side instead of spending twice.
  Future<TransferStarsResponse> transfer({
    required String recipientUserId,
    required int amount,
    required String idempotencyKey,
  }) async {
    final data = await _client.post(
      '/Stars/Transfer',
      body: {'RecipientUserId': recipientUserId, 'Amount': amount, 'IdempotencyKey': idempotencyKey},
    );
    return TransferStarsResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Same idempotency discipline as [transfer].
  Future<ActivatePremiumTrialResponse> activatePremiumTrial(String idempotencyKey) async {
    final data = await _client.post(
      '/Stars/PremiumTrial/Activate',
      body: {'IdempotencyKey': idempotencyKey},
    );
    return ActivatePremiumTrialResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Starts a one-time Stripe Checkout session for a Stars package. The
  /// response carries the hosted-checkout `Url` plus the purchase id, so
  /// `StarsController.refreshAfterResume` can poll [getPurchaseStatus]
  /// directly for an exact per-purchase answer.
  Future<CreateStarsCheckoutSessionResponse> createCheckoutSession(String packageId) async {
    final data = await _client.post('/Stars/Purchases/CheckoutSession', body: {'PackageId': packageId});
    return CreateStarsCheckoutSessionResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Status of a single purchase - polled by [StarsController.refreshAfterResume] after a
  /// checkout URL is opened externally.
  Future<StarPurchaseStatusResponse> getPurchaseStatus(String purchaseId) async {
    final data = await _client.get('/Stars/Purchases/$purchaseId/Status');
    return StarPurchaseStatusResponse.fromJson(data as Map<String, dynamic>);
  }
}
