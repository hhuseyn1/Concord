import 'direct_message_response.dart';
import 'json_utils.dart';
import 'public_profile_response.dart';

class ConversationResponse {
  const ConversationResponse({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    final rawLastMessage = json.field('LastMessage') as Map<String, dynamic>?;
    return ConversationResponse(
      id: json.field('Id') as String,
      otherUser: PublicProfileResponse.fromJson(json.field('OtherUser') as Map<String, dynamic>),
      lastMessage: rawLastMessage == null ? null : DirectMessageResponse.fromJson(rawLastMessage),
      lastMessageAt: parseNullableDateTime(json.field('LastMessageAt')),
      unreadCount: json.field('UnreadCount') as int,
    );
  }

  final String id;
  final PublicProfileResponse otherUser;
  final DirectMessageResponse? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationResponse copyWith({
    PublicProfileResponse? otherUser,
    DirectMessageResponse? lastMessage,
    bool clearLastMessage = false,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationResponse(
      id: id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
