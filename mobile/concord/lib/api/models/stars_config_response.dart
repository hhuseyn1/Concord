import 'json_utils.dart';

class StarPackage {
  const StarPackage({
    required this.id,
    required this.stars,
    required this.priceAmount,
    required this.currency,
  });

  factory StarPackage.fromJson(Map<String, dynamic> json) {
    return StarPackage(
      id: json.field('Id') as String,
      stars: json.field('Stars') as int,
      priceAmount: (json.field('PriceAmount') as num).toDouble(),
      currency: json.field('Currency') as String? ?? 'usd',
    );
  }

  final String id;
  final int stars;
  final double priceAmount;
  final String currency;
}

class StarsConfigResponse {
  const StarsConfigResponse({
    required this.chatRewardAmount,
    required this.chatRewardCooldownSeconds,
    required this.chatRewardDailyCap,
    required this.premiumTrialCostStars,
    required this.premiumTrialDurationDays,
    required this.packages,
  });

  factory StarsConfigResponse.fromJson(Map<String, dynamic> json) {
    final rawPackages = json.field('Packages') as List<dynamic>? ?? const [];
    return StarsConfigResponse(
      chatRewardAmount: json.field('ChatRewardAmount') as int? ?? 0,
      chatRewardCooldownSeconds: json.field('ChatRewardCooldownSeconds') as int? ?? 0,
      chatRewardDailyCap: json.field('ChatRewardDailyCap') as int? ?? 0,
      premiumTrialCostStars: json.field('PremiumTrialCostStars') as int? ?? 0,
      premiumTrialDurationDays: json.field('PremiumTrialDurationDays') as int? ?? 0,
      packages: rawPackages
          .map((e) => StarPackage.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int chatRewardAmount;
  final int chatRewardCooldownSeconds;
  final int chatRewardDailyCap;
  final int premiumTrialCostStars;
  final int premiumTrialDurationDays;
  final List<StarPackage> packages;
}
