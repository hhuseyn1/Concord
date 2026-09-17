import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';

class MessagesHubState {
  const MessagesHubState();
}

class MessagesHubController extends StateNotifier<MessagesHubState> {
  MessagesHubController(this._ref) : super(const MessagesHubState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (isAuthenticated && !wasAuthenticated) {
        unawaited(_connectHub());
      } else if (!isAuthenticated && wasAuthenticated) {
        unawaited(_teardownForSignOut());
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  MessagesHub? _hub;

  final Set<String> _joinedChannelIds = {};

  MessagesHub? get hub => _hub;

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = MessagesHub(tokenStorage: tokenStorage);
    _hub = hub;

    hub.onReconnected(({String? connectionId}) {
      unawaited(_rejoinChannels());
    });

    try {
      await hub.connect();
    } catch (_) {
      return;
    }

    unawaited(_rejoinChannels());
  }

  Future<void> joinChannel(String channelId) async {
    final hub = _hub;
    _joinedChannelIds.add(channelId);
    if (hub == null) return;
    try {
      await hub.joinChannel(channelId);
    } catch (_) {
    }
  }

  Future<void> leaveChannel(String channelId) async {
    _joinedChannelIds.remove(channelId);
    final hub = _hub;
    if (hub == null) return;
    unawaited(hub.leaveChannel(channelId).catchError((_) {}));
  }

  Future<void> _rejoinChannels() async {
    final hub = _hub;
    if (hub == null) return;
    for (final id in _joinedChannelIds) {
      try {
        await hub.joinChannel(id);
      } catch (_) {
      }
    }
  }

  Future<void> _teardownForSignOut() async {
    await _teardownConnection();
    if (mounted) state = const MessagesHubState();
  }

  Future<void> _teardownConnection() async {
    _joinedChannelIds.clear();
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

final messagesHubControllerProvider = StateNotifierProvider<MessagesHubController, MessagesHubState>((ref) {
  return MessagesHubController(ref);
});
