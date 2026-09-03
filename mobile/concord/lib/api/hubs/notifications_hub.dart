import 'dart:async';

import 'hub_base.dart';
import 'hub_events.dart';

class NotificationsHub extends ConcordHub {
  NotificationsHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/notifications') {
    connection.on('NotificationCreated', (args) {
      _notificationCreated.add(NotificationCreatedEvent.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _notificationCreated = StreamController<NotificationCreatedEvent>.broadcast();

  Stream<NotificationCreatedEvent> get onNotificationCreated => _notificationCreated.stream;

  Future<void> dispose() async {
    await connection.stop();
    await _notificationCreated.close();
  }
}
