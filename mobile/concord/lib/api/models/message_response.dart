import 'json_utils.dart';
import 'message_like.dart';
import 'public_profile_response.dart';
import 'reaction_summary_response.dart';

class MessageResponse implements MessageLike {
  const MessageResponse({
    required this.id,
    required this.channelId,
    required this.sender,
    required this.content,
    required this.created,
    required this.editedAtUtc,
    required this.attachmentUrl,
    required this.replyToMessageId,
    required this.reactions,
    required this.pinnedAt,
    required this.pinnedByUserId,
    required this.forwardedFromSenderId,
    required this.forwardedFromCreatedAt,
    required this.mentionedUserIds,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final rawReactions = json.field('Reactions') as List<dynamic>? ?? const [];
    return MessageResponse(
      id: json.field('Id') as String,
      channelId: json.field('ChannelId') as String,
      sender: PublicProfileResponse.fromJson(json.field('Sender') as Map<String, dynamic>),
      content: json.field('Content') as String?,
      created: parseDateTime(json.field('Created')),
      editedAtUtc: parseNullableDateTime(json.field('EditedAtUtc')),
      attachmentUrl: json.field('AttachmentUrl') as String?,
      replyToMessageId: json.field('ReplyToMessageId') as String?,
      reactions: rawReactions
          .map((e) => ReactionSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      pinnedAt: parseNullableDateTime(json.field('PinnedAt')),
      pinnedByUserId: json.field('PinnedByUserId') as String?,
      forwardedFromSenderId: json.field('ForwardedFromSenderId') as String?,
      forwardedFromCreatedAt: parseNullableDateTime(json.field('ForwardedFromCreatedAt')),
      mentionedUserIds: parseStringList(json.field('MentionedUserIds')),
    );
  }

  @override
  final String id;
  final String channelId;
  @override
  final PublicProfileResponse sender;

  @override
  final String? content;
  @override
  final DateTime created;
  @override
  final DateTime? editedAtUtc;
  @override
  final String? attachmentUrl;
  @override
  final String? replyToMessageId;
  @override
  final List<ReactionSummaryResponse> reactions;
  @override
  final DateTime? pinnedAt;
  @override
  final String? pinnedByUserId;
  @override
  final String? forwardedFromSenderId;
  @override
  final DateTime? forwardedFromCreatedAt;
  @override
  final List<String> mentionedUserIds;
}
