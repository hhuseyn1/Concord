import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function startCall(conversationId, type) {
  return request(`DirectMessages/Conversations/${conversationId}/Calls`, { method: 'POST', body: { Type: type } });
}

export async function acceptCall(conversationId, callId) {
  return request(`DirectMessages/Conversations/${conversationId}/Calls/${callId}:Accept`, { method: 'POST' });
}

export async function declineCall(conversationId, callId) {
  return request(`DirectMessages/Conversations/${conversationId}/Calls/${callId}:Decline`, { method: 'POST' });
}

export async function endCall(conversationId, callId) {
  return request(`DirectMessages/Conversations/${conversationId}/Calls/${callId}:End`, { method: 'POST' });
}

export async function getCalls(conversationId, { page, pageSize } = {}) {
  return request(`DirectMessages/Conversations/${conversationId}/Calls`, { query: buildPagingQuery(page, pageSize) });
}
