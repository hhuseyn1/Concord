import 'json_utils.dart';

class TwoFactorStatusResponse {
  const TwoFactorStatusResponse({
    required this.enabled,
    required this.enabledAt,
    required this.setupPending,
    required this.remainingRecoveryCodes,
  });

  factory TwoFactorStatusResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorStatusResponse(
      enabled: json.field('Enabled') as bool,
      enabledAt: parseNullableDateTime(json.field('EnabledAt')),
      setupPending: json.field('SetupPending') as bool,
      remainingRecoveryCodes: json.field('RemainingRecoveryCodes') as int,
    );
  }

  final bool enabled;
  final DateTime? enabledAt;

  /// True when a secret exists but has never been confirmed with a code.
  final bool setupPending;
  final int remainingRecoveryCodes;
}
