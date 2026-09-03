import { createHubConnection } from './hubConnection';

export function createServersHub() {
  const connection = createHubConnection('/hubs/servers');

  return {
    connection,
    start: () => connection.start(),
    stop: () => connection.stop(),

    joinServer: (serverId) => connection.invoke('JoinServer', serverId),

    leaveServer: (serverId) => connection.invoke('LeaveServer', serverId),

    onChannelCreated(handler) {
      connection.on('ChannelCreated', handler);
      return () => connection.off('ChannelCreated', handler);
    },
    onChannelUpdated(handler) {
      connection.on('ChannelUpdated', handler);
      return () => connection.off('ChannelUpdated', handler);
    },
    onServerUpdated(handler) {
      connection.on('ServerUpdated', handler);
      return () => connection.off('ServerUpdated', handler);
    },
    onChannelDeleted(handler) {
      connection.on('ChannelDeleted', handler);
      return () => connection.off('ChannelDeleted', handler);
    },
    onServerMemberJoined(handler) {
      connection.on('ServerMemberJoined', handler);
      return () => connection.off('ServerMemberJoined', handler);
    },
    onServerMemberLeft(handler) {
      connection.on('ServerMemberLeft', handler);
      return () => connection.off('ServerMemberLeft', handler);
    },
    onRemovedFromServer(handler) {
      connection.on('RemovedFromServer', handler);
      return () => connection.off('RemovedFromServer', handler);
    },
    onServerModerationChanged(handler) {
      connection.on('ServerModerationChanged', handler);
      return () => connection.off('ServerModerationChanged', handler);
    },
  };
}
