import { createHubConnection } from './hubConnection';

export function createMessagesHub() {
  const connection = createHubConnection('/hubs/messages');

  return {
    connection,

    start: () => connection.start(),

    stop: () => connection.stop(),

    joinChannel: (channelId) => connection.invoke('JoinChannel', channelId),

    leaveChannel: (channelId) => connection.invoke('LeaveChannel', channelId),

    onMessageReceived(handler) {
      connection.on('MessageReceived', handler);
      return () => connection.off('MessageReceived', handler);
    },

    onMessageEdited(handler) {
      connection.on('MessageEdited', handler);
      return () => connection.off('MessageEdited', handler);
    },

    onMessageDeleted(handler) {
      connection.on('MessageDeleted', handler);
      return () => connection.off('MessageDeleted', handler);
    },

    onMessageReactionsChanged(handler) {
      connection.on('MessageReactionsChanged', handler);
      return () => connection.off('MessageReactionsChanged', handler);
    },

    onMessagePinned(handler) {
      connection.on('MessagePinned', handler);
      return () => connection.off('MessagePinned', handler);
    },

    onMessageUnpinned(handler) {
      connection.on('MessageUnpinned', handler);
      return () => connection.off('MessageUnpinned', handler);
    },

    notifyTyping: (channelId) => connection.invoke('Typing', channelId),

    onUserTyping(handler) {
      connection.on('UserTyping', handler);
      return () => connection.off('UserTyping', handler);
    },

    stopTyping: (channelId) => connection.invoke('StopTyping', channelId),

    onUserStoppedTyping(handler) {
      connection.on('UserStoppedTyping', handler);
      return () => connection.off('UserStoppedTyping', handler);
    },
  };
}
