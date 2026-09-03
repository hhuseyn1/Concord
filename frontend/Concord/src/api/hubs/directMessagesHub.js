import { createHubConnection } from './hubConnection';

export function createDirectMessagesHub() {
  const connection = createHubConnection('/hubs/direct-messages');

  return {
    connection,

    start: () => connection.start(),

    stop: () => connection.stop(),

    onDirectMessageReceived(handler) {
      connection.on('DirectMessageReceived', handler);
      return () => connection.off('DirectMessageReceived', handler);
    },

    onDirectMessageEdited(handler) {
      connection.on('DirectMessageEdited', handler);
      return () => connection.off('DirectMessageEdited', handler);
    },

    onDirectMessageDeleted(handler) {
      connection.on('DirectMessageDeleted', handler);
      return () => connection.off('DirectMessageDeleted', handler);
    },

    onDirectMessageReactionsChanged(handler) {
      connection.on('DirectMessageReactionsChanged', handler);
      return () => connection.off('DirectMessageReactionsChanged', handler);
    },

    onDirectMessagePinned(handler) {
      connection.on('DirectMessagePinned', handler);
      return () => connection.off('DirectMessagePinned', handler);
    },

    onDirectMessageUnpinned(handler) {
      connection.on('DirectMessageUnpinned', handler);
      return () => connection.off('DirectMessageUnpinned', handler);
    },

    onDirectCallParticipantJoined(handler) {
      connection.on('DirectCallParticipantJoined', handler);
      return () => connection.off('DirectCallParticipantJoined', handler);
    },

    onDirectCallParticipantLeft(handler) {
      connection.on('DirectCallParticipantLeft', handler);
      return () => connection.off('DirectCallParticipantLeft', handler);
    },

    onDirectCallInitiated(handler) {
      connection.on('DirectCallInitiated', handler);
      return () => connection.off('DirectCallInitiated', handler);
    },

    onDirectCallAccepted(handler) {
      connection.on('DirectCallAccepted', handler);
      return () => connection.off('DirectCallAccepted', handler);
    },

    onDirectCallDeclined(handler) {
      connection.on('DirectCallDeclined', handler);
      return () => connection.off('DirectCallDeclined', handler);
    },

    onDirectCallEnded(handler) {
      connection.on('DirectCallEnded', handler);
      return () => connection.off('DirectCallEnded', handler);
    },

    onConversationRead(handler) {
      connection.on('ConversationRead', handler);
      return () => connection.off('ConversationRead', handler);
    },

    notifyTyping: (conversationId) => connection.invoke('Typing', conversationId),

    onUserTyping(handler) {
      connection.on('UserTyping', handler);
      return () => connection.off('UserTyping', handler);
    },

    stopTyping: (conversationId) => connection.invoke('StopTyping', conversationId),

    onUserStoppedTyping(handler) {
      connection.on('UserStoppedTyping', handler);
      return () => connection.off('UserStoppedTyping', handler);
    },
  };
}
