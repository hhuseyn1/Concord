import { createHubConnection } from './hubConnection';

export function createNotificationsHub() {
  const connection = createHubConnection('/hubs/notifications');

  return {
    connection,
    start: () => connection.start(),
    stop: () => connection.stop(),

    onNotificationCreated(handler) {
      connection.on('NotificationCreated', handler);
      return () => connection.off('NotificationCreated', handler);
    },
  };
}
