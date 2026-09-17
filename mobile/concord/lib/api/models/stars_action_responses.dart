import 'enums.dart';
import 'json_utils.dart';

/// `POST Stars/Transfer` - the sender's balance after the transfer.
class TransferStarsResponse {
  const TransferStarsResponse({required this.balance});

  factory TransferStarsResponse.fromJson(Map<String, dynamic> json) {
    return TransferStarsResponse(balance: json.field('Balance') as int? ?? 0);
  }

  final int balance;
}

/// `POST Stars/PremiumTrial/Activate`.
class ActivatePremiumTrialResponse {
  const ActivatePremiumTrialResponse({required this.balance, required this.premiumTrialExpiresAt});

  factory ActivatePremiumTrialResponse.fromJson(Map<String, dynamic> json) {
    return ActivatePremiumTrialResponse(
      balance: json.field('Balance') as int? ?? 0,
      premiumTrialExpiresAt: parseDateTime(json.field('PremiumTrialExpiresAt')),
    );
  }

  final int balance;
  final DateTime premiumTrialExpiresAt;
}

/// `POST Stars/Purchases/CheckoutSession`. Unlike the shared (subscription)
/// `CheckoutSessionResponse`, this carries the purchase id back too, so a
/// native client - which never receives the web success-redirect the backend
/// otherwise hands the id out through - can poll
/// `GET Stars/Purchases/{purchaseId}/Status` directly.
class CreateStarsCheckoutSessionResponse {
  const CreateStarsCheckoutSessionResponse({required this.url, required this.purchaseId});

  factory CreateStarsCheckoutSessionResponse.fromJson(Map<String, dynamic> json) {
    return CreateStarsCheckoutSessionResponse(
      url: json.field('Url') as String,
      purchaseId: json.field('PurchaseId') as String,
    );
  }

  final String url;
  final String purchaseId;
}

/// `GET Stars/Purchases/{purchaseId}/Status`.
class StarPurchaseStatusResponse {
  const StarPurchaseStatusResponse({required this.status});

  factory StarPurchaseStatusResponse.fromJson(Map<String, dynamic> json) {
    return StarPurchaseStatusResponse(status: StarPurchaseStatus.fromWire(json.field('Status')));
  }

  final StarPurchaseStatus status;
}
