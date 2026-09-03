import 'enums.dart';
import 'json_utils.dart';
import 'public_profile_response.dart';

class GlobalSearchResultResponse {
  const GlobalSearchResultResponse({
    required this.messageId,
    required this.sourceType,
    required this.serverId,
    required this.channelId,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.created,
  });

  factory GlobalSearchResultResponse.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResultResponse(
      messageId: json.field('MessageId') as String,
      sourceType: MessageSourceType.fromWire(json.field('SourceType')),
      serverId: json.field('ServerId') as String?,
      channelId: json.field('ChannelId') as String?,
      conversationId: json.field('ConversationId') as String?,
      sender: PublicProfileResponse.fromJson(json.field('Sender') as Map<String, dynamic>),
      content: json.field('Content') as String?,
      created: parseDateTime(json.field('Created')),
    );
  }

  final String messageId;
  final MessageSourceType sourceType;

  final String? serverId;

  final String? channelId;

  final String? conversationId;

  final PublicProfileResponse sender;
  final String? content;
  final DateTime created;
}
