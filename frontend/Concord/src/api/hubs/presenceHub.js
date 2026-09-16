import { createHubConnection } from './hubConnection';

export function createPresenceHub() {
  const connection = createHubConnection('/hubs/presence');

  return {
    connection,
    start: () => connection.start(),
    stop: () => connection.stop(),

    setStatus: (status) => connection.invoke('SetStatus', status),
    heartbeat: () => connection.invoke('Heartbeat'),

    onPresenceChanged(handler) {
      connection.on('PresenceChanged', handler);
      return () => connection.off('PresenceChanged', handler);
    },
  };
}
