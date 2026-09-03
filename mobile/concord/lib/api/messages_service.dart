import 'api_client.dart';
import 'models/message_response.dart';
import 'models/paged_result.dart';

class MessagesService {
  MessagesService(this._client);

  final ApiClient _client;

  Future<PagedResult<MessageResponse>> listMessages(
    String serverId,
    String channelId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final data = await _client.get(
      '/Servers/$serverId/Channels/$channelId/Messages',
      query: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(data as Map<String, dynamic>, MessageResponse.fromJson);
  }

  Future<MessageResponse> sendMessage(
    String serverId,
    String channelId, {
    required String content,
    String? attachmentUrl,
    String? replyToMessageId,
  }) async {
    final data = await _client.post(
      '/Servers/$serverId/Channels/$channelId/Messages',
      body: {
        'Content': content,
        'AttachmentUrl': attachmentUrl,
        'ReplyToMessageId': replyToMessageId,
      },
    );
    return MessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MessageResponse> editMessage(
    String serverId,
    String channelId,
    String messageId, {
    required String content,
  }) async {
    final data = await _client.put(
      '/Servers/$serverId/Channels/$channelId/Messages/$messageId',
      body: {'Content': content},
    );
    return MessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> deleteMessage(String serverId, String channelId, String messageId) async {
    final data = await _client.delete('/Servers/$serverId/Channels/$channelId/Messages/$messageId');
    return data as bool;
  }

  Future<MessageResponse> toggleReaction(
    String serverId,
    String channelId,
    String messageId,
    String emoji,
  ) async {
    final data = await _client.post(
      '/Servers/$serverId/Channels/$channelId/Messages/$messageId/Reactions',
      body: {'Emoji': emoji},
    );
    return MessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MessageResponse> pinMessage(String serverId, String channelId, String messageId) async {
    final data = await _client.post('/Servers/$serverId/Channels/$channelId/Messages/$messageId:Pin');
    return MessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MessageResponse> unpinMessage(String serverId, String channelId, String messageId) async {
    final data = await _client.post('/Servers/$serverId/Channels/$channelId/Messages/$messageId:Unpin');
    return MessageResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MessageResponse>> getPinnedMessages(String serverId, String channelId) async {
    final data = await _client.get('/Servers/$serverId/Channels/$channelId/Messages/Pinned');
    return (data as List<dynamic>)
        .map((e) => MessageResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Forwards a message sourced from this channel into another channel or DM conversation.
  /// Exactly one of [targetChannelId]/[targetConversationId] must be set — mirrors the backend's
  /// `ForwardMessageRequest`. The response shape depends on which target was chosen (a
  /// `MessageResponse` or a `DirectMessageResponse`), which callers don't need: the newly created
  /// message reaches its destination thread over that thread's own SignalR hub, same as any other
  /// send, so this just needs to succeed or throw.
  Future<void> forwardMessage(
    String serverId,
    String channelId,
    String messageId, {
    String? targetChannelId,
    String? targetConversationId,
  }) async {
    await _client.post(
      '/Servers/$serverId/Channels/$channelId/Messages/$messageId/Forward',
      body: {
        'TargetChannelId': targetChannelId,
        'TargetConversationId': targetConversationId,
      },
    );
  }
}
