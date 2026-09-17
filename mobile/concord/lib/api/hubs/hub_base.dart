import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../token_storage.dart';
import 'hub_connection_factory.dart';

abstract class ConcordHub {
  ConcordHub({required String hubPath, required TokenStorage tokenStorage, String? baseUrl})
      : connection = buildHubConnection(hubPath: hubPath, tokenStorage: tokenStorage, baseUrl: baseUrl);

  @protected
  final HubConnection connection;

  HubConnectionState? get state => connection.state;

  bool get isConnected => connection.state == HubConnectionState.Connected;

  Stream<HubConnectionState> get stateStream => connection.stateStream;

  Future<void> connect() async {
    if (connection.state == HubConnectionState.Disconnected) {
      await connection.start();
    }
  }

  Future<void> disconnect() => connection.stop();

  void onReconnected(ReconnectedCallback callback) {
    connection.onreconnected(callback);
  }
}
