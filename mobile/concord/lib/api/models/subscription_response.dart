import 'enums.dart';
import 'json_utils.dart';

class SubscriptionResponse {
  const SubscriptionResponse({
    required this.status,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      status: SubscriptionStatus.fromWire(json.field('Status')),
      currentPeriodEnd: parseNullableDateTime(json.field('CurrentPeriodEnd')),
      cancelAtPeriodEnd: json.field('CancelAtPeriodEnd') as bool? ?? false,
    );
  }

  final SubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
}
