import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';

final activeDmConversationIdProvider = StateProvider<String?>((ref) => null);

class ConversationsState {
  const ConversationsState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadError,
    this.page = 0,
  });

  final List<ConversationResponse> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadError;
  final int page;

  ConversationsState copyWith({
    List<ConversationResponse>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? loadError,
    bool clearLoadError = false,
    int? page,
  }) {
    return ConversationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      page: page ?? this.page,
    );
  }
}

class ConversationsController extends StateNotifier<ConversationsState> {
  ConversationsController(this._ref) : super(const ConversationsState()) {
    unawaited(_init());
  }

  static const _pageSize = 30;

  final Ref _ref;
  DirectMessagesHub? _hub;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  DirectMessagesService get _service => _ref.read(directMessagesServiceProvider);
  String? get _currentUserId => _ref.read(authControllerProvider).profile?.id;

  Future<void> _init() async {
    await loadInitial();
    await _connectHub();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final result = await _service.listConversations(page: 1, pageSize: _pageSize);
      if (_disposed) return;
      state = state.copyWith(items: result.items, isLoading: false, hasMore: result.hasNextPage, page: 1);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e.message);
    }
  }

  Future<void> retryInitialLoad() => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    try {
      final result = await _service.listConversations(page: nextPage, pageSize: _pageSize);
      if (_disposed) return;
      final existingIds = state.items.map((c) => c.id).toSet();
      final more = result.items.where((c) => !existingIds.contains(c.id));
      state = state.copyWith(
        items: [...state.items, ...more],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        page: nextPage,
      );
    } on ApiException {
      if (_disposed) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = DirectMessagesHub(tokenStorage: tokenStorage);
    _hub = hub;

    _subscriptions.addAll([
      hub.onMessageReceived.listen(_handleMessageEvent),
      hub.onMessageEdited.listen(_handleMessageEvent),
    ]);

    try {
      await hub.connect();
    } catch (_) {
    }
  }

  void _handleMessageEvent(DirectMessageResponse message) {
    final index = state.items.indexWhere((c) => c.id == message.conversationId);
    if (index == -1) {
      unawaited(loadInitial());
      return;
    }

    final skipUnreadBump = message.sender.id == _currentUserId ||
        _ref.read(activeDmConversationIdProvider) == message.conversationId;

    final existing = state.items[index];
    final updated = existing.copyWith(
      lastMessage: message,
      lastMessageAt: message.created,
      unreadCount: skipUnreadBump ? existing.unreadCount : existing.unreadCount + 1,
    );

    final reordered = [updated, ...state.items.where((c) => c.id != message.conversationId)];
    state = state.copyWith(items: reordered);
  }

  void markConversationRead(String conversationId) {
    final index = state.items.indexWhere((c) => c.id == conversationId);
    if (index == -1 || state.items[index].unreadCount == 0) return;
    final updated = state.items[index].copyWith(unreadCount: 0);
    state = state.copyWith(items: [for (final c in state.items) if (c.id == conversationId) updated else c]);
  }

  void upsertConversation(ConversationResponse conversation) {
    final withoutExisting = state.items.where((c) => c.id != conversation.id);
    state = state.copyWith(items: [conversation, ...withoutExisting]);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final hub = _hub;
    if (hub != null) unawaited(hub.dispose());
    super.dispose();
  }
}

final conversationsControllerProvider =
    StateNotifierProvider.autoDispose<ConversationsController, ConversationsState>(
  (ref) => ConversationsController(ref),
);
