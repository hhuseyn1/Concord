import 'api_client.dart';
import 'models/conversation_response.dart';
import 'models/direct_message_response.dart';
import 'models/paged_result.dart';

class DirectMessagesService {
  DirectMessagesService(this._client);

  final ApiClient _client;

  Future<PagedResult<ConversationResponse>> listConversations({int page = 1, int pageSize = 30}) async {
    final data = await _client.get('/DirectMessages/Conversations', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, ConversationResponse.fromJson);
  }

  Future<ConversationResponse> createOrGetConversation(String userId) async {
    final data = await _client.post('/DirectMessages/Conversations/$userId');
    return ConversationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PagedResult<DirectMessageResponse>> listMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final data = await _client.get(
      '/DirectMessages/Conversations/$conversationId/Messages',
      query: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(data as Map<String, dynamic>, DirectMessageResponse.fromJson);
  }

  Future<PagedResult<DirectMessageResponse>> searchMessages(
    String conversationId,
    String query, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final data = await _client.get(
      '/DirectMessages/Conversations/$conversationId/Messages/Search',
      query: {'query': query, 'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(data as Map<String, dynamic>, DirectMessageResponse.fromJson);
  }

  Future<DirectMessageResponse> sendMessage(
    String conversationId, {
    required String content,
    String? attachmentUrl,
    String? replyToMessageId,
  }) async {
    final data = await _client.post(
      '/DirectMessages/Conversations/$conversationId/Messages',
      body: {
        'Content': content,
        'AttachmentUrl': attachmentUrl,
        'ReplyToMessageId': replyToMessageId,
      },
    );
    return DirectMessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<DirectMessageResponse> editMessage(
    String conversationId,
    String messageId, {
    required String content,
  }) async {
    final data = await _client.put(
      '/DirectMessages/Conversations/$conversationId/Messages/$messageId',
      body: {'Content': content},
    );
    return DirectMessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    final data = await _client.delete('/DirectMessages/Conversations/$conversationId/Messages/$messageId');
    return data as bool;
  }

  Future<DirectMessageResponse> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final data = await _client.post(
      '/DirectMessages/Conversations/$conversationId/Messages/$messageId/Reactions',
      body: {'Emoji': emoji},
    );
    return DirectMessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<DirectMessageResponse> pinMessage(String conversationId, String messageId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Messages/$messageId:Pin');
    return DirectMessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<DirectMessageResponse> unpinMessage(String conversationId, String messageId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Messages/$messageId:Unpin');
    return DirectMessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DirectMessageResponse>> getPinnedMessages(String conversationId) async {
    final data = await _client.get('/DirectMessages/Conversations/$conversationId/Messages/Pinned');
    return (data as List<dynamic>)
        .map((e) => DirectMessageResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> forwardMessage(
    String conversationId,
    String messageId, {
    String? targetChannelId,
    String? targetConversationId,
  }) async {
    await _client.post(
      '/DirectMessages/Conversations/$conversationId/Messages/$messageId/Forward',
      body: {
        'TargetChannelId': targetChannelId,
        'TargetConversationId': targetConversationId,
      },
    );
  }
}
