import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';

/// Session-scoped MessagesHub connection, shared across every open channel
/// screen - mirrors ServersController/PresenceController. Previously each
/// channel screen opened (and tore down) its own MessagesHub connection,
/// paying a full negotiate+handshake on every channel switch. Now the
/// connection persists for the whole session; a channel screen only joins/
/// leaves its own group on this one connection.
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

  // Channels currently expected to be joined. SignalR groups are keyed by
  // connection id server-side, so a successful automatic reconnect (a new
  // connection id) silently drops this membership - onReconnected below
  // rejoins everything in this set.
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

    // A channel screen may have already called joinChannel() while this
    // connect() was still in flight - that invoke would have failed silently
    // (caught below), so catch it up now the same way a reconnect would.
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
