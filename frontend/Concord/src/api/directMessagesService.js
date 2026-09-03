import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getConversations({ page, pageSize } = {}) {
  return request('DirectMessages/Conversations', { query: buildPagingQuery(page, pageSize) });
}

export async function createOrGetConversation(userId) {
  return request(`DirectMessages/Conversations/${userId}`, { method: 'POST' });
}

export async function getDirectMessages(conversationId, { page, pageSize } = {}) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages`, {
    query: buildPagingQuery(page, pageSize),
  });
}

export async function sendDirectMessage(conversationId, { Content, AttachmentUrl = null, ReplyToMessageId = null }) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages`, {
    method: 'POST',
    body: { Content, AttachmentUrl, ReplyToMessageId },
  });
}

export async function editDirectMessage(conversationId, messageId, content) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}`, {
    method: 'PUT',
    body: { Content: content },
  });
}

export async function deleteDirectMessage(conversationId, messageId) {
  await request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}`, { method: 'DELETE' });
}

export async function toggleDirectMessageReaction(conversationId, messageId, emoji) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}/Reactions`, {
    method: 'POST',
    body: { Emoji: emoji },
  });
}

export async function searchDirectMessages(conversationId, query, { page, pageSize } = {}) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/Search`, {
    query: { query, ...buildPagingQuery(page, pageSize) },
  });
}

export async function pinDirectMessage(conversationId, messageId) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}:Pin`, { method: 'POST' });
}

export async function unpinDirectMessage(conversationId, messageId) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}:Unpin`, { method: 'POST' });
}

export async function getPinnedDirectMessages(conversationId) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/Pinned`);
}

export async function forwardDirectMessage(conversationId, messageId, { targetChannelId = null, targetConversationId = null }) {
  return request(`DirectMessages/Conversations/${conversationId}/Messages/${messageId}/Forward`, {
    method: 'POST',
    body: { TargetChannelId: targetChannelId, TargetConversationId: targetConversationId },
  });
}
