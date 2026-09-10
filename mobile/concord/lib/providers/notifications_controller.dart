import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';
import 'friends_providers.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadError,
    this.page = 0,
  });

  final List<NotificationResponse> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadError;
  final int page;

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationResponse>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? loadError,
    bool clearLoadError = false,
    int? page,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      page: page ?? this.page,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._ref) : super(const NotificationsState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (isAuthenticated && !wasAuthenticated) {
        unawaited(_init());
      } else if (!isAuthenticated && wasAuthenticated) {
        unawaited(_teardownForSignOut());
      }
    }, fireImmediately: true);
  }

  static const _pageSize = 30;

  final Ref _ref;
  bool _disposed = false;

  NotificationsHub? _hub;
  StreamSubscription<NotificationCreatedEvent>? _subscription;

  NotificationsService get _service => _ref.read(notificationsServiceProvider);

  Future<void> _init() async {
    await loadInitial();
    await _connectHub();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final result = await _service.list(page: 1, pageSize: _pageSize);
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
      final result = await _service.list(page: nextPage, pageSize: _pageSize);
      if (_disposed) return;
      final existingIds = state.items.map((n) => n.id).toSet();
      final fresh = result.items.where((n) => !existingIds.contains(n.id));
      state = state.copyWith(
        items: [...state.items, ...fresh],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        page: nextPage,
      );
    } on ApiException {
      if (_disposed) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markRead(String notificationId) async {
    await _service.markRead(notificationId);
    if (_disposed) return;
    final now = DateTime.now();
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (n.id == notificationId) n.copyWith(isRead: true, readAt: now) else n,
      ],
    );
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    if (_disposed) return;
    final now = DateTime.now();
    state = state.copyWith(items: [for (final n in state.items) n.isRead ? n : n.copyWith(isRead: true, readAt: now)]);
  }

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = NotificationsHub(tokenStorage: tokenStorage);
    _hub = hub;
    _subscription = hub.onNotificationCreated.listen(_handleNotificationCreated);

    try {
      await hub.connect();
    } catch (_) {
    }
  }

  static const _friendRequestTypes = {
    NotificationType.friendRequestReceived,
    NotificationType.friendRequestAccepted,
    NotificationType.friendRequestDeclined,
    NotificationType.friendRequestCancelled,
  };

  void _handleNotificationCreated(NotificationCreatedEvent event) {
    unawaited(loadInitial());
    if (_friendRequestTypes.contains(event.type)) {
      _ref.invalidate(incomingRequestsProvider);
      _ref.invalidate(outgoingRequestsProvider);
      _ref.invalidate(friendsListControllerProvider);
      _ref.invalidate(blockedListControllerProvider);
    }

    // Mirrors the web client's toast/sound behavior: this hub push is the only signal a message or
    // friend request arrived while the app is open (there's no OS-level push yet), so a muted sound
    // cue plus a light buzz is the whole notice the user gets - skip both only if they've muted
    // notifications outright.
    final profile = _ref.read(authControllerProvider).profile;
    if (profile?.notificationsMuted ?? false) return;
    if (profile?.notificationsSoundEnabled ?? false) unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _teardownForSignOut() async {
    await _teardownConnection();
    if (mounted) state = const NotificationsState();
  }

  Future<void> _teardownConnection() async {
    await _subscription?.cancel();
    _subscription = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) unawaited(hub.dispose());
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_teardownConnection());
    super.dispose();
  }
}

final notificationsControllerProvider = StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref);
});
