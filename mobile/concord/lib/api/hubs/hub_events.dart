import '../models/enums.dart';
import '../models/json_utils.dart';

class PresenceChangedEvent {
  const PresenceChangedEvent({required this.userId, required this.status, required this.lastSeenAt});

  factory PresenceChangedEvent.fromJson(Map<String, dynamic> json) {
    return PresenceChangedEvent(
      userId: json.field('userId') as String,
      status: PresenceStatus.fromWire(json.field('status')),
      lastSeenAt: parseNullableDateTime(json.field('lastSeenAt')),
    );
  }

  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeenAt;
}

class NotificationCreatedEvent {
  const NotificationCreatedEvent({
    required this.type,
    required this.relatedUserId,
    required this.created,
  });

  factory NotificationCreatedEvent.fromJson(Map<String, dynamic> json) {
    return NotificationCreatedEvent(
      type: NotificationType.fromWire(json.field('type')),
      relatedUserId: json.field('relatedUserId') as String,
      created: parseDateTime(json.field('created')),
    );
  }

  final NotificationType type;
  final String relatedUserId;
  final DateTime created;
}

class TypingEvent {
  const TypingEvent({required this.channelId, required this.userId});

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      channelId: json.field('channelId') as String,
      userId: json.field('userId') as String,
    );
  }

  final String channelId;
  final String userId;
}

class DirectMessageTypingEvent {
  const DirectMessageTypingEvent({required this.conversationId, required this.userId});

  factory DirectMessageTypingEvent.fromJson(Map<String, dynamic> json) {
    return DirectMessageTypingEvent(
      conversationId: json.field('conversationId') as String,
      userId: json.field('userId') as String,
    );
  }

  final String conversationId;
  final String userId;
}

class DirectMessageDeletedEvent {
  const DirectMessageDeletedEvent({required this.conversationId, required this.messageId});

  factory DirectMessageDeletedEvent.fromJson(Map<String, dynamic> json) {
    return DirectMessageDeletedEvent(
      conversationId: json.field('conversationId') as String,
      messageId: json.field('messageId') as String,
    );
  }

  final String conversationId;
  final String messageId;
}

class ConversationReadEvent {
  const ConversationReadEvent({required this.conversationId, required this.userId, required this.readAt});

  factory ConversationReadEvent.fromJson(Map<String, dynamic> json) {
    return ConversationReadEvent(
      conversationId: json.field('conversationId') as String,
      userId: json.field('userId') as String,
      readAt: parseDateTime(json.field('readAt')),
    );
  }

  final String conversationId;
  final String userId;
  final DateTime readAt;
}

class VoiceParticipantEvent {
  const VoiceParticipantEvent({required this.channelId, required this.userId});

  factory VoiceParticipantEvent.fromJson(Map<String, dynamic> json) {
    return VoiceParticipantEvent(
      channelId: json.field('channelId') as String,
      userId: json.field('userId') as String,
    );
  }

  final String channelId;
  final String userId;
}

class DirectCallParticipantEvent {
  const DirectCallParticipantEvent({required this.conversationId, required this.userId});

  factory DirectCallParticipantEvent.fromJson(Map<String, dynamic> json) {
    return DirectCallParticipantEvent(
      conversationId: json.field('conversationId') as String,
      userId: json.field('userId') as String,
    );
  }

  final String conversationId;
  final String userId;
}

class ChannelDeletedEvent {
  const ChannelDeletedEvent({required this.serverId, required this.channelId});

  factory ChannelDeletedEvent.fromJson(Map<String, dynamic> json) {
    return ChannelDeletedEvent(
      serverId: json.field('serverId') as String,
      channelId: json.field('channelId') as String,
    );
  }

  final String serverId;
  final String channelId;
}

class ServerMemberEvent {
  const ServerMemberEvent({required this.serverId, required this.userId});

  factory ServerMemberEvent.fromJson(Map<String, dynamic> json) {
    return ServerMemberEvent(
      serverId: json.field('serverId') as String,
      userId: json.field('userId') as String,
    );
  }

  final String serverId;
  final String userId;
}

class RemovedFromServerEvent {
  const RemovedFromServerEvent({required this.serverId});

  factory RemovedFromServerEvent.fromJson(Map<String, dynamic> json) {
    return RemovedFromServerEvent(serverId: json.field('serverId') as String);
  }

  final String serverId;
}

class ServerModerationChangedEvent {
  const ServerModerationChangedEvent({required this.serverId, required this.targetUserId});

  factory ServerModerationChangedEvent.fromJson(Map<String, dynamic> json) {
    return ServerModerationChangedEvent(
      serverId: json.field('serverId') as String,
      targetUserId: json.field('targetUserId') as String,
    );
  }

  final String serverId;
  final String targetUserId;
}
