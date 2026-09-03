import 'json_utils.dart';

/// Moderation state of one member — mirrors `ModerationController`'s
/// `MemberModerationResponse` (mute/timeout, P1).
class MemberModerationResponse {
  const MemberModerationResponse({
    required this.userId,
    required this.isMuted,
    required this.timedOutUntil,
    required this.timedOutByUserId,
    required this.timeoutReason,
  });

  factory MemberModerationResponse.fromJson(Map<String, dynamic> json) {
    return MemberModerationResponse(
      userId: json.field('UserId') as String,
      isMuted: json.field('IsMuted') as bool,
      timedOutUntil: parseNullableDateTime(json.field('TimedOutUntil')),
      timedOutByUserId: json.field('TimedOutByUserId') as String?,
      timeoutReason: json.field('TimeoutReason') as String?,
    );
  }

  final String userId;
  final bool isMuted;
  final DateTime? timedOutUntil;
  final String? timedOutByUserId;
  final String? timeoutReason;
}
