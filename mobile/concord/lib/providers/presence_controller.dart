import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';
import 'friends_providers.dart';

class PresenceState {
  const PresenceState({this.myStatus = PresenceStatus.offline});

  final PresenceStatus myStatus;

  PresenceState copyWith({PresenceStatus? myStatus}) {
    return PresenceState(myStatus: myStatus ?? this.myStatus);
  }
}

class PresenceController extends StateNotifier<PresenceState> {
  PresenceController(this._ref) : super(const PresenceState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (isAuthenticated && !wasAuthenticated) {
        unawaited(_connectHub());
      } else if (!isAuthenticated && wasAuthenticated) {
        unawaited(_teardownForSignOut());
      }
      if (previous?.profile == null && next.profile != null) {
        state = state.copyWith(myStatus: next.profile!.status);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  static const _heartbeatInterval = Duration(seconds: 60);

  PresenceHub? _hub;
  StreamSubscription<PresenceChangedEvent>? _subscription;
  Timer? _heartbeatTimer;

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = PresenceHub(tokenStorage: tokenStorage);
    _hub = hub;
    _subscription = hub.onPresenceChanged.listen(_handlePresenceChanged);

    try {
      await hub.connect();
    } catch (_) {
    }

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (!hub.isConnected) return;
      unawaited(hub.heartbeat().catchError((_) {}));
    });
  }

  void _handlePresenceChanged(PresenceChangedEvent event) {
    if (!_ref.exists(friendsListControllerProvider)) return;
    _ref
        .read(friendsListControllerProvider.notifier)
        .patchWhere(
          (profile) => profile.id == event.userId,
          (profile) => profile.copyWith(
            status: event.status,
            lastSeenAt: event.lastSeenAt,
            clearLastSeenAt: event.lastSeenAt == null,
          ),
        );
  }

  Future<void> setStatus(PresenceStatus status) async {
    final previous = state.myStatus;
    state = state.copyWith(myStatus: status);
    try {
      await _hub?.setStatus(status);
    } catch (_) {
      state = state.copyWith(myStatus: previous);
    }
  }

  Future<void> _teardownForSignOut() async {
    await _teardownConnection();
    if (mounted) state = const PresenceState();
  }

  Future<void> _teardownConnection() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    final hub = _hub;
    _hub = null;
    if (hub != null) unawaited(hub.dispose());
  }

  @override
  void dispose() {
    unawaited(_teardownConnection());
    super.dispose();
  }
}

final presenceControllerProvider = StateNotifierProvider<PresenceController, PresenceState>((ref) {
  return PresenceController(ref);
});
