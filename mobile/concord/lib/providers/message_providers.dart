import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'message_thread_controller.dart';

class ChannelKey {
  const ChannelKey(this.serverId, this.channelId);

  final String serverId;
  final String channelId;

  @override
  bool operator ==(Object other) =>
      other is ChannelKey && other.serverId == serverId && other.channelId == channelId;

  @override
  int get hashCode => Object.hash(serverId, channelId);
}

class MessagesState {
  const MessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadError,
    this.loadMoreError,
    this.typingUserIds = const {},
    this.page = 0,
  });

  final List<MessageResponse> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadError;
  final String? loadMoreError;
  final Set<String> typingUserIds;
  final int page;

  MessagesState copyWith({
    List<MessageResponse>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? loadError,
    bool clearLoadError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    Set<String>? typingUserIds,
    int? page,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      typingUserIds: typingUserIds ?? this.typingUserIds,
      page: page ?? this.page,
    );
  }
}

class MessagesController extends StateNotifier<MessagesState> implements MessageThreadController {
  MessagesController(this._ref, this.serverId, this.channelId) : super(const MessagesState()) {
    unawaited(_init());
  }

  static const _pageSize = 30;

  static const _typingExpiry = Duration(seconds: 6);

  final Ref _ref;
  final String serverId;
  final String channelId;

  MessagesHub? _hub;
  final Map<String, Timer> _typingTimeouts = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  MessagesService get _service => _ref.read(messagesServiceProvider);

  Future<void> _init() async {
    await loadInitial();
    await _connectHub();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final result = await _service.listMessages(serverId, channelId, page: 1, pageSize: _pageSize);
      if (_disposed) return;
      state = state.copyWith(
        messages: result.items.reversed.toList(),
        isLoading: false,
        hasMore: result.hasNextPage,
        page: 1,
      );
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e.message);
    }
  }

  Future<void> retryInitialLoad() => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.page + 1;
    try {
      final result = await _service.listMessages(serverId, channelId, page: nextPage, pageSize: _pageSize);
      if (_disposed) return;
      final existingIds = state.messages.map((m) => m.id).toSet();
      final older = result.items.reversed.where((m) => !existingIds.contains(m.id));
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        page: nextPage,
      );
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: e.message);
    }
  }

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = MessagesHub(tokenStorage: tokenStorage);
    _hub = hub;

    _subscriptions.addAll([
      hub.onMessageReceived.listen(_handleReceived),
      hub.onMessageEdited.listen(_handleUpdated),
      hub.onMessageDeleted.listen(_handleDeleted),
      hub.onMessageReactionsChanged.listen(_handleUpdated),
      hub.onMessagePinned.listen(_handleUpdated),
      hub.onMessageUnpinned.listen(_handleUpdated),
      hub.onUserTyping.listen(_handleTyping),
      hub.onUserStoppedTyping.listen(_handleStoppedTyping),
    ]);

    try {
      await hub.connect();
      if (_disposed) return;
      await hub.joinChannel(channelId);
    } catch (_) {
    }
  }

  void _handleReceived(MessageResponse message) {
    if (message.channelId != channelId) return;
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _handleUpdated(MessageResponse message) {
    if (message.channelId != channelId) return;
    state = state.copyWith(
      messages: [for (final m in state.messages) if (m.id == message.id) message else m],
    );
  }

  void _handleDeleted(String messageId) {
    if (!state.messages.any((m) => m.id == messageId)) return;
    state = state.copyWith(messages: state.messages.where((m) => m.id != messageId).toList());
  }

  void _handleTyping(TypingEvent event) {
    if (event.channelId != channelId) return;
    _typingTimeouts.remove(event.userId)?.cancel();
    _typingTimeouts[event.userId] = Timer(_typingExpiry, () {
      _typingTimeouts.remove(event.userId);
      if (!state.typingUserIds.contains(event.userId)) return;
      state = state.copyWith(typingUserIds: {...state.typingUserIds}..remove(event.userId));
    });
    if (state.typingUserIds.contains(event.userId)) return;
    state = state.copyWith(typingUserIds: {...state.typingUserIds, event.userId});
  }

  void _handleStoppedTyping(TypingEvent event) {
    if (event.channelId != channelId) return;
    _typingTimeouts.remove(event.userId)?.cancel();
    if (!state.typingUserIds.contains(event.userId)) return;
    state = state.copyWith(typingUserIds: {...state.typingUserIds}..remove(event.userId));
  }

  @override
  Future<void> notifyTyping() async {
    try {
      await _hub?.notifyTyping(channelId);
    } catch (_) {
    }
  }

  @override
  Future<void> stopTyping() async {
    try {
      await _hub?.stopTyping(channelId);
    } catch (_) {
    }
  }

  @override
  Future<MessageResponse> sendMessage({
    required String content,
    String? attachmentUrl,
    String? replyToMessageId,
  }) async {
    final message = await _service.sendMessage(
      serverId,
      channelId,
      content: content,
      attachmentUrl: attachmentUrl,
      replyToMessageId: replyToMessageId,
    );
    if (!state.messages.any((m) => m.id == message.id)) {
      state = state.copyWith(messages: [...state.messages, message]);
    }
    return message;
  }

  @override
  Future<void> editMessage(String messageId, String content) async {
    final message = await _service.editMessage(serverId, channelId, messageId, content: content);
    _handleUpdated(message);
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    final previous = state.messages;
    if (!previous.any((m) => m.id == messageId)) return false;
    state = state.copyWith(messages: previous.where((m) => m.id != messageId).toList());
    try {
      return await _service.deleteMessage(serverId, channelId, messageId);
    } catch (_) {
      if (!_disposed) state = state.copyWith(messages: previous);
      rethrow;
    }
  }

  @override
  Future<void> toggleReaction(String messageId, String emoji) async {
    final message = await _service.toggleReaction(serverId, channelId, messageId, emoji);
    _handleUpdated(message);
  }

  @override
  Future<void> pinMessage(String messageId) async {
    final message = await _service.pinMessage(serverId, channelId, messageId);
    _handleUpdated(message);
  }

  @override
  Future<void> unpinMessage(String messageId) async {
    final message = await _service.unpinMessage(serverId, channelId, messageId);
    _handleUpdated(message);
  }

  @override
  Future<void> forwardMessage(String messageId, {String? targetChannelId, String? targetConversationId}) {
    return _service.forwardMessage(
      serverId,
      channelId,
      messageId,
      targetChannelId: targetChannelId,
      targetConversationId: targetConversationId,
    );
  }

  @override
  MessageResponse? findById(String id) {
    for (final message in state.messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _typingTimeouts.values) {
      timer.cancel();
    }
    _typingTimeouts.clear();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final hub = _hub;
    if (hub != null) {
      unawaited(hub.stopTyping(channelId).catchError((_) {}));
      unawaited(hub.leaveChannel(channelId).catchError((_) {}));
      unawaited(hub.dispose());
    }
    super.dispose();
  }
}

final messagesControllerProvider =
    StateNotifierProvider.autoDispose.family<MessagesController, MessagesState, ChannelKey>((ref, key) {
  return MessagesController(ref, key.serverId, key.channelId);
});
