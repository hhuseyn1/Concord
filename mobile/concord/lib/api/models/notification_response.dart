import 'enums.dart';
import 'json_utils.dart';
import 'public_profile_response.dart';

class NotificationResponse {
  const NotificationResponse({
    required this.id,
    required this.type,
    required this.relatedUser,
    required this.isRead,
    required this.readAt,
    required this.created,
    required this.contextServerId,
    required this.contextChannelId,
    required this.contextConversationId,
    required this.contextMessageId,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final relatedUserJson = json.field('RelatedUser') as Map<String, dynamic>?;
    return NotificationResponse(
      id: json.field('Id') as String,
      type: NotificationType.fromWire(json.field('Type')),
      relatedUser: relatedUserJson == null ? null : PublicProfileResponse.fromJson(relatedUserJson),
      isRead: json.field('IsRead') as bool,
      readAt: parseNullableDateTime(json.field('ReadAt')),
      created: parseDateTime(json.field('Created')),
      contextServerId: json.field('ContextServerId') as String?,
      contextChannelId: json.field('ContextChannelId') as String?,
      contextConversationId: json.field('ContextConversationId') as String?,
      contextMessageId: json.field('ContextMessageId') as String?,
    );
  }

  final String id;
  final NotificationType type;
  final PublicProfileResponse? relatedUser;
  final bool isRead;
  final DateTime? readAt;
  final DateTime created;

  final String? contextServerId;
  final String? contextChannelId;
  final String? contextConversationId;
  final String? contextMessageId;

  NotificationResponse copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationResponse(
      id: id,
      type: type,
      relatedUser: relatedUser,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      created: created,
      contextServerId: contextServerId,
      contextChannelId: contextChannelId,
      contextConversationId: contextConversationId,
      contextMessageId: contextMessageId,
    );
  }
}
