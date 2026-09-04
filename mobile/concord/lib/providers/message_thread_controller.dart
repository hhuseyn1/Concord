import '../api/models/message_like.dart';

abstract class MessageThreadController {
  Future<void> editMessage(String messageId, String content);

  Future<bool> deleteMessage(String messageId);

  Future<void> toggleReaction(String messageId, String emoji);

  Future<void> pinMessage(String messageId);

  Future<void> unpinMessage(String messageId);

  Future<void> forwardMessage(String messageId, {String? targetChannelId, String? targetConversationId});

  Future<MessageLike> sendMessage({
    required String content,
    String? attachmentUrl,
    String? replyToMessageId,
  });

  Future<void> notifyTyping();

  Future<void> stopTyping();

  MessageLike? findById(String id);
}
