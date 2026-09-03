import { request } from './httpClient';

export async function getVoiceToken(channelId) {
  return request(`Channels/${channelId}/Voice/Token`, { method: 'POST' });
}

export async function getVoiceParticipants(channelId) {
  return request(`Channels/${channelId}/Voice/Participants`);
}
