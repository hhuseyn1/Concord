import 'json_utils.dart';

/// `GET Stars/Wallet` - balance plus the two Premium flags.
///
/// [premiumTrialActive] is specifically "the Stars-funded trial is unexpired",
/// while [hasActivePremium] is "Premium from *any* source" (an Active/PastDue
/// Stripe subscription or the trial). The trial card needs both to tell
/// "already trialling" apart from "already a paying subscriber".
class StarWalletResponse {
  const StarWalletResponse({
    required this.balance,
    required this.premiumTrialActive,
    required this.premiumTrialExpiresAt,
    required this.hasActivePremium,
  });

  factory StarWalletResponse.fromJson(Map<String, dynamic> json) {
    return StarWalletResponse(
      balance: json.field('Balance') as int? ?? 0,
      premiumTrialActive: json.field('PremiumTrialActive') as bool? ?? false,
      premiumTrialExpiresAt: parseNullableDateTime(json.field('PremiumTrialExpiresAt')),
      hasActivePremium: json.field('HasActivePremium') as bool? ?? false,
    );
  }

  final int balance;
  final bool premiumTrialActive;
  final DateTime? premiumTrialExpiresAt;
  final bool hasActivePremium;

  StarWalletResponse copyWith({int? balance, bool? premiumTrialActive, DateTime? premiumTrialExpiresAt, bool? hasActivePremium}) {
    return StarWalletResponse(
      balance: balance ?? this.balance,
      premiumTrialActive: premiumTrialActive ?? this.premiumTrialActive,
      premiumTrialExpiresAt: premiumTrialExpiresAt ?? this.premiumTrialExpiresAt,
      hasActivePremium: hasActivePremium ?? this.hasActivePremium,
    );
  }
}
