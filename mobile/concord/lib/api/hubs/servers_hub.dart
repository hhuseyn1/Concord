import 'dart:async';

import '../models/channel_response.dart';
import '../models/server_response.dart';
import 'hub_base.dart';
import 'hub_events.dart';

class ServersHub extends ConcordHub {
  ServersHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/servers') {
    connection.on('ChannelCreated', (args) {
      _channelCreated.add(ChannelResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ChannelUpdated', (args) {
      _channelUpdated.add(ChannelResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ChannelDeleted', (args) {
      _channelDeleted.add(ChannelDeletedEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ServerMemberJoined', (args) {
      _serverMemberJoined.add(ServerMemberEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ServerMemberLeft', (args) {
      _serverMemberLeft.add(ServerMemberEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('RemovedFromServer', (args) {
      _removedFromServer.add(RemovedFromServerEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ServerUpdated', (args) {
      _serverUpdated.add(ServerResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ServerModerationChanged', (args) {
      _serverModerationChanged.add(ServerModerationChangedEvent.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _channelCreated = StreamController<ChannelResponse>.broadcast();
  final _channelUpdated = StreamController<ChannelResponse>.broadcast();
  final _channelDeleted = StreamController<ChannelDeletedEvent>.broadcast();
  final _serverMemberJoined = StreamController<ServerMemberEvent>.broadcast();
  final _serverMemberLeft = StreamController<ServerMemberEvent>.broadcast();
  final _removedFromServer = StreamController<RemovedFromServerEvent>.broadcast();
  final _serverUpdated = StreamController<ServerResponse>.broadcast();
  final _serverModerationChanged = StreamController<ServerModerationChangedEvent>.broadcast();

  Stream<ChannelResponse> get onChannelCreated => _channelCreated.stream;

  Stream<ChannelResponse> get onChannelUpdated => _channelUpdated.stream;

  Stream<ChannelDeletedEvent> get onChannelDeleted => _channelDeleted.stream;

  Stream<ServerMemberEvent> get onServerMemberJoined => _serverMemberJoined.stream;

  Stream<ServerMemberEvent> get onServerMemberLeft => _serverMemberLeft.stream;

  Stream<RemovedFromServerEvent> get onRemovedFromServer => _removedFromServer.stream;

  Stream<ServerResponse> get onServerUpdated => _serverUpdated.stream;

  Stream<ServerModerationChangedEvent> get onServerModerationChanged => _serverModerationChanged.stream;

  Future<void> joinServer(String serverId) => connection.invoke('JoinServer', args: [serverId]);

  Future<void> leaveServer(String serverId) => connection.invoke('LeaveServer', args: [serverId]);

  Future<void> dispose() async {
    await connection.stop();
    await _channelCreated.close();
    await _channelUpdated.close();
    await _channelDeleted.close();
    await _serverMemberJoined.close();
    await _serverMemberLeft.close();
    await _removedFromServer.close();
    await _serverUpdated.close();
    await _serverModerationChanged.close();
  }
}
