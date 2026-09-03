import { request } from './httpClient';

export async function getDirectVoiceToken(conversationId) {
  return request(`DirectMessages/Conversations/${conversationId}/Voice/Token`, { method: 'POST' });
}

export async function getDirectVoiceParticipants(conversationId) {
  return request(`DirectMessages/Conversations/${conversationId}/Voice/Participants`);
}
