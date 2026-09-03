import { createHubConnection } from './hubConnection';

export function createVoiceHub() {
  const connection = createHubConnection('/hubs/voice');

  return {
    connection,
    start: () => connection.start(),
    stop: () => connection.stop(),

    joinChannel: (channelId) => connection.invoke('JoinChannel', channelId),

    leaveChannel: (channelId) => connection.invoke('LeaveChannel', channelId),

    onParticipantJoined(handler) {
      connection.on('VoiceParticipantJoined', handler);
      return () => connection.off('VoiceParticipantJoined', handler);
    },

    onParticipantLeft(handler) {
      connection.on('VoiceParticipantLeft', handler);
      return () => connection.off('VoiceParticipantLeft', handler);
    },
  };
}
