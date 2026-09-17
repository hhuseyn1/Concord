import 'json_utils.dart';

/// One buyable real-money Stars package from `GET Stars/Config`.
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
      // Decimal on the wire: JSON gives us an int for a round price and a double otherwise.
      priceAmount: (json.field('PriceAmount') as num).toDouble(),
      // Stripe-style lowercase code ("usd").
      currency: json.field('Currency') as String? ?? 'usd',
    );
  }

  final String id;
  final int stars;
  final double priceAmount;
  final String currency;
}

/// Server-owned Stars tuning knobs. Every number the Stars UI shows (reward
/// amount, daily cap, trial cost/duration, package catalog) comes from here -
/// nothing is hardcoded client-side, so changing `StarsConstants` on the
/// backend is enough to change the copy on both platforms.
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
