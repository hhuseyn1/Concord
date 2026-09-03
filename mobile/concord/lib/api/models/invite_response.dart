import 'json_utils.dart';

class InviteResponse {
  const InviteResponse({
    required this.code,
    required this.expiresAtUtc,
    required this.maxUses,
    required this.useCount,
  });

  factory InviteResponse.fromJson(Map<String, dynamic> json) {
    return InviteResponse(
      code: json.field('Code') as String,
      expiresAtUtc: parseNullableDateTime(json.field('ExpiresAtUtc')),
      maxUses: json.field('MaxUses') as int?,
      useCount: json.field('UseCount') as int,
    );
  }

  final String code;
  final DateTime? expiresAtUtc;
  final int? maxUses;
  final int useCount;
}
