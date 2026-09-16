import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';
import 'server_member_list_providers.dart';
import 'server_providers.dart';

class ServersState {
  const ServersState();
}

class ServersController extends StateNotifier<ServersState> {
  ServersController(this._ref) : super(const ServersState()) {
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

  ServersHub? _hub;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  final Set<String> _joinedServerIds = {};

  bool _myServersListenerRegistered = false;

  Future<void> _connectHub() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final hub = ServersHub(tokenStorage: tokenStorage);
    _hub = hub;

    _subscriptions.addAll([
      hub.onChannelCreated.listen((channel) => _ref.invalidate(channelsProvider(channel.serverId))),
      hub.onChannelUpdated.listen((channel) => _ref.invalidate(channelsProvider(channel.serverId))),
      hub.onChannelDeleted.listen((event) => _ref.invalidate(channelsProvider(event.serverId))),
      hub.onServerMemberJoined.listen((event) {
        _ref.invalidate(serverMembersProvider(event.serverId));
        _ref.invalidate(serverMemberListControllerProvider(event.serverId));
      }),
      hub.onServerMemberLeft.listen((event) {
        _ref.invalidate(serverMembersProvider(event.serverId));
        _ref.invalidate(serverMemberListControllerProvider(event.serverId));
      }),
      hub.onRemovedFromServer.listen(_handleRemovedFromServer),
      hub.onServerUpdated.listen((_) => _ref.invalidate(myServersProvider)),
      hub.onServerModerationChanged.listen((_) {}),
    ]);

    hub.onReconnected(({String? connectionId}) {
      unawaited(_rejoinServers());
    });

    try {
      await hub.connect();
    } catch (_) {
    }

    if (!_myServersListenerRegistered) {
      _myServersListenerRegistered = true;
      _ref.listen<AsyncValue<List<ServerResponse>>>(myServersProvider, (previous, next) {
        final servers = next.valueOrNull;
        if (servers == null || _hub == null) return;
        unawaited(_syncJoinedServers(servers));
      }, fireImmediately: true);
    } else {
      final servers = _ref.read(myServersProvider).valueOrNull;
      if (servers != null) unawaited(_syncJoinedServers(servers));
    }
  }

  Future<void> _syncJoinedServers(List<ServerResponse> servers) async {
    final hub = _hub;
    if (hub == null) return;
    final targetIds = servers.map((s) => s.id).toSet();

    for (final id in targetIds.difference(_joinedServerIds)) {
      try {
        await hub.joinServer(id);
        _joinedServerIds.add(id);
      } catch (_) {
      }
    }
    for (final id in _joinedServerIds.difference(targetIds)) {
      unawaited(hub.leaveServer(id).catchError((_) {}));
      _joinedServerIds.remove(id);
    }
  }

  Future<void> _rejoinServers() async {
    final hub = _hub;
    if (hub == null) return;
    for (final id in _joinedServerIds) {
      try {
        await hub.joinServer(id);
      } catch (_) {
      }
    }
  }

  void _handleRemovedFromServer(RemovedFromServerEvent event) {
    _joinedServerIds.remove(event.serverId);
    unawaited(_hub?.leaveServer(event.serverId).catchError((_) {}));
    _ref.invalidate(myServersProvider);
  }

  Future<void> _teardownForSignOut() async {
    await _teardownConnection();
    if (mounted) state = const ServersState();
  }

  Future<void> _teardownConnection() async {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _joinedServerIds.clear();
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

final serversControllerProvider = StateNotifierProvider<ServersController, ServersState>((ref) {
  return ServersController(ref);
});
