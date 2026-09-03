import 'enums.dart';
import 'json_utils.dart';

class CallResponse {
  const CallResponse({
    required this.id,
    required this.conversationId,
    required this.initiatorId,
    required this.calleeId,
    required this.type,
    required this.status,
    required this.created,
    required this.answeredAt,
    required this.endedAt,
    required this.durationSeconds,
  });

  factory CallResponse.fromJson(Map<String, dynamic> json) {
    return CallResponse(
      id: json.field('Id') as String,
      conversationId: json.field('ConversationId') as String,
      initiatorId: json.field('InitiatorId') as String,
      calleeId: json.field('CalleeId') as String,
      type: CallType.fromWire(json.field('Type')),
      status: CallStatus.fromWire(json.field('Status')),
      created: parseDateTime(json.field('Created')),
      answeredAt: parseNullableDateTime(json.field('AnsweredAt')),
      endedAt: parseNullableDateTime(json.field('EndedAt')),
      durationSeconds: json.field('DurationSeconds') as int?,
    );
  }

  final String id;
  final String conversationId;
  final String initiatorId;
  final String calleeId;
  final CallType type;
  final CallStatus status;
  final DateTime created;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  final int? durationSeconds;
}
