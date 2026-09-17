import 'api_client.dart';
import 'models/paged_result.dart';
import 'models/star_transaction_response.dart';
import 'models/star_wallet_response.dart';
import 'models/stars_action_responses.dart';
import 'models/stars_config_response.dart';

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

  Future<ActivatePremiumTrialResponse> activatePremiumTrial(String idempotencyKey) async {
    final data = await _client.post(
      '/Stars/PremiumTrial/Activate',
      body: {'IdempotencyKey': idempotencyKey},
    );
    return ActivatePremiumTrialResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CreateStarsCheckoutSessionResponse> createCheckoutSession(String packageId) async {
    final data = await _client.post('/Stars/Purchases/CheckoutSession', body: {'PackageId': packageId});
    return CreateStarsCheckoutSessionResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<StarPurchaseStatusResponse> getPurchaseStatus(String purchaseId) async {
    final data = await _client.get('/Stars/Purchases/$purchaseId/Status');
    return StarPurchaseStatusResponse.fromJson(data as Map<String, dynamic>);
  }
}
