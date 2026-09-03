import 'dart:async';

import 'hub_base.dart';
import 'hub_events.dart';

class VoiceHub extends ConcordHub {
  VoiceHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/voice') {
    connection.on('VoiceParticipantJoined', (args) {
      _participantJoined.add(VoiceParticipantEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('VoiceParticipantLeft', (args) {
      _participantLeft.add(VoiceParticipantEvent.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _participantJoined = StreamController<VoiceParticipantEvent>.broadcast();
  final _participantLeft = StreamController<VoiceParticipantEvent>.broadcast();

  Stream<VoiceParticipantEvent> get onParticipantJoined => _participantJoined.stream;

  Stream<VoiceParticipantEvent> get onParticipantLeft => _participantLeft.stream;

  Future<void> joinChannel(String channelId) => connection.invoke('JoinChannel', args: [channelId]);

  Future<void> leaveChannel(String channelId) => connection.invoke('LeaveChannel', args: [channelId]);

  Future<void> dispose() async {
    await connection.stop();
    await _participantJoined.close();
    await _participantLeft.close();
  }
}
