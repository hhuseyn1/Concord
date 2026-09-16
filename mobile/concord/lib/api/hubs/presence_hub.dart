import 'dart:async';

import '../models/enums.dart';
import 'hub_base.dart';
import 'hub_events.dart';

class PresenceHub extends ConcordHub {
  PresenceHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/presence') {
    connection.on('PresenceChanged', (args) {
      _presenceChanged.add(PresenceChangedEvent.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _presenceChanged = StreamController<PresenceChangedEvent>.broadcast();

  Stream<PresenceChangedEvent> get onPresenceChanged => _presenceChanged.stream;

  Future<void> setStatus(PresenceStatus status) {
    assert(status != PresenceStatus.offline, 'Offline is server-derived and rejected by SetStatus.');
    return connection.invoke('SetStatus', args: [status.toWire()]);
  }

  Future<void> heartbeat() => connection.invoke('Heartbeat');

  Future<void> dispose() async {
    await connection.stop();
    await _presenceChanged.close();
  }
}
