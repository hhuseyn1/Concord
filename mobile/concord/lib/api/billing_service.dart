import 'api_client.dart';
import 'models/checkout_session_response.dart';
import 'models/portal_session_response.dart';
import 'models/subscription_response.dart';

class BillingService {
  BillingService(this._client);

  final ApiClient _client;

  Future<CheckoutSessionResponse> createCheckoutSession() async {
    final data = await _client.post('/Billing/CheckoutSession');
    return CheckoutSessionResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<SubscriptionResponse> getSubscription() async {
    final data = await _client.get('/Billing/Subscription');
    return SubscriptionResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PortalSessionResponse> createPortalSession() async {
    final data = await _client.post('/Billing/PortalSession');
    return PortalSessionResponse.fromJson(data as Map<String, dynamic>);
  }
}
