import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'message_thread_controller.dart';

class DirectMessagesState {
  const DirectMessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadError,
    this.loadMoreError,
    this.typingUserIds = const {},
    this.page = 0,
    this.otherReadAt,
  });

  final List<DirectMessageResponse> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ApiException? loadError;
  final ApiException? loadMoreError;
  final Set<String> typingUserIds;
  final int page;

  final DateTime? otherReadAt;

  DirectMessagesState copyWith({
    List<DirectMessageResponse>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ApiException? loadError,
    bool clearLoadError = false,
    ApiException? loadMoreError,
    bool clearLoadMoreError = false,
    Set<String>? typingUserIds,
    int? page,
    DateTime? otherReadAt,
  }) {
    return DirectMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      typingUserIds: typingUserIds ?? this.typingUserIds,
      page: page ?? this.page,
      otherReadAt: otherReadAt ?? this.otherReadAt,
    );
  }
}

class DirectMessagesController extends StateNotifier<DirectMessagesState> implements MessageThreadController {
  DirectMessagesController(this._ref, this.conversationId) : super(const DirectMessagesState()) {
    unawaited(_init());
  }

  static const _pageSize = 30;
  static const _typingExpiry = Duration(seconds: 6);

  final Ref _ref;
  final String conversationId;

  DirectMessagesHub? _hub;
  final Map<String, Timer> _typingTimeouts = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  DirectMessagesService get _service => _ref.read(directMessagesServiceProvider);

  Future<void> _init() async {
    await loadInitial();
    await _connectHub();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final result = await _service.listMessages(conversationId, page: 1, pageSize: _pageSize);
      if (_disposed) return;
      state = state.copyWith(
        messages: result.items.reversed.toList(),
        isLoading: false,
        hasMore: result.hasNextPage,
        page: 1,
      );
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e);
    }
  }

  Future<void> retryInitialLoad() => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.page + 1;
    try {
      final result = await _service.listMessages(conversationId, page: nextPage, pageSize: _pageSize);
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
      state = state.copyWith(isLoadingMore: false, loadMoreError: e);
    }
  }

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = DirectMessagesHub(tokenStorage: tokenStorage);
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
      hub.onConversationRead.listen(_handleConversationRead),
    ]);

    try {
      await hub.connect();
    } catch (_) {
    }
  }

  void _handleReceived(DirectMessageResponse message) {
    if (message.conversationId != conversationId) return;
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _handleUpdated(DirectMessageResponse message) {
    if (message.conversationId != conversationId) return;
    state = state.copyWith(
      messages: [for (final m in state.messages) if (m.id == message.id) message else m],
    );
  }

  void _handleDeleted(DirectMessageDeletedEvent event) {
    if (event.conversationId != conversationId) return;
    if (!state.messages.any((m) => m.id == event.messageId)) return;
    state = state.copyWith(messages: state.messages.where((m) => m.id != event.messageId).toList());
  }

  void _handleTyping(DirectMessageTypingEvent event) {
    if (event.conversationId != conversationId) return;
    _typingTimeouts.remove(event.userId)?.cancel();
    _typingTimeouts[event.userId] = Timer(_typingExpiry, () {
      _typingTimeouts.remove(event.userId);
      if (!state.typingUserIds.contains(event.userId)) return;
      state = state.copyWith(typingUserIds: {...state.typingUserIds}..remove(event.userId));
    });
    if (state.typingUserIds.contains(event.userId)) return;
    state = state.copyWith(typingUserIds: {...state.typingUserIds, event.userId});
  }

  void _handleStoppedTyping(DirectMessageTypingEvent event) {
    if (event.conversationId != conversationId) return;
    _typingTimeouts.remove(event.userId)?.cancel();
    if (!state.typingUserIds.contains(event.userId)) return;
    state = state.copyWith(typingUserIds: {...state.typingUserIds}..remove(event.userId));
  }

  void _handleConversationRead(ConversationReadEvent event) {
    if (event.conversationId != conversationId) return;
    if (state.otherReadAt != null && !event.readAt.isAfter(state.otherReadAt!)) return;
    state = state.copyWith(otherReadAt: event.readAt);
  }

  @override
  Future<void> notifyTyping() async {
    try {
      await _hub?.notifyTyping(conversationId);
    } catch (_) {
    }
  }

  @override
  Future<void> stopTyping() async {
    try {
      await _hub?.stopTyping(conversationId);
    } catch (_) {
    }
  }

  @override
  Future<DirectMessageResponse> sendMessage({
    required String content,
    String? attachmentUrl,
    String? replyToMessageId,
  }) async {
    final message = await _service.sendMessage(
      conversationId,
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
    final message = await _service.editMessage(conversationId, messageId, content: content);
    _handleUpdated(message);
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    final previous = state.messages;
    if (!previous.any((m) => m.id == messageId)) return false;
    state = state.copyWith(messages: previous.where((m) => m.id != messageId).toList());
    try {
      return await _service.deleteMessage(conversationId, messageId);
    } catch (_) {
      if (!_disposed) state = state.copyWith(messages: previous);
      rethrow;
    }
  }

  @override
  Future<void> toggleReaction(String messageId, String emoji) async {
    final message = await _service.toggleReaction(conversationId, messageId, emoji);
    _handleUpdated(message);
  }

  @override
  Future<void> pinMessage(String messageId) async {
    final message = await _service.pinMessage(conversationId, messageId);
    _handleUpdated(message);
  }

  @override
  Future<void> unpinMessage(String messageId) async {
    final message = await _service.unpinMessage(conversationId, messageId);
    _handleUpdated(message);
  }

  @override
  Future<void> forwardMessage(String messageId, {String? targetChannelId, String? targetConversationId}) {
    return _service.forwardMessage(
      conversationId,
      messageId,
      targetChannelId: targetChannelId,
      targetConversationId: targetConversationId,
    );
  }

  @override
  DirectMessageResponse? findById(String id) {
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
      unawaited(hub.stopTyping(conversationId).catchError((_) {}));
      unawaited(hub.dispose());
    }
    super.dispose();
  }
}

final directMessagesControllerProvider =
    StateNotifierProvider.autoDispose.family<DirectMessagesController, DirectMessagesState, String>(
  (ref, conversationId) => DirectMessagesController(ref, conversationId),
);
