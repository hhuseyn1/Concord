import 'api_client.dart';
import 'models/checkout_session_response.dart';
import 'models/portal_session_response.dart';
import 'models/subscription_response.dart';

class BillingService {
  BillingService(this._client);

  final ApiClient _client;

  /// Starts a Stripe Checkout session for a Premium subscription. The returned URL's
  /// success/cancel redirects are fixed backend config pointing at the web app - see the
  /// resume-polling comment on `BillingController` for how this app copes with that.
  Future<CheckoutSessionResponse> createCheckoutSession() async {
    final data = await _client.post('/Billing/CheckoutSession');
    return CheckoutSessionResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<SubscriptionResponse> getSubscription() async {
    final data = await _client.get('/Billing/Subscription');
    return SubscriptionResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Starts a Stripe-hosted Customer Portal session (manage payment method, view invoices,
  /// cancel-at-period-end). Same fixed-return-url caveat as [createCheckoutSession].
  Future<PortalSessionResponse> createPortalSession() async {
    final data = await _client.post('/Billing/PortalSession');
    return PortalSessionResponse.fromJson(data as Map<String, dynamic>);
  }
}
