import 'json_utils.dart';

class VoiceParticipantSummary {
  const VoiceParticipantSummary({
    required this.userId,
    required this.identity,
    required this.joinedAt,
  });

  factory VoiceParticipantSummary.fromJson(Map<String, dynamic> json) {
    return VoiceParticipantSummary(
      userId: json.field('UserId') as String,
      identity: json.field('Identity') as String,
      joinedAt: parseDateTime(json.field('JoinedAt')),
    );
  }

  final String userId;
  final String identity;
  final DateTime joinedAt;
}
