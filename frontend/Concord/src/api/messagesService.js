import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getMessages(serverId, channelId, { page, pageSize } = {}) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages`, {
    query: buildPagingQuery(page, pageSize),
  });
}

export async function sendMessage(serverId, channelId, { Content, AttachmentUrl = null, ReplyToMessageId = null }) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages`, {
    method: 'POST',
    body: { Content, AttachmentUrl, ReplyToMessageId },
  });
}

export async function editMessage(serverId, channelId, messageId, content) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}`, {
    method: 'PUT',
    body: { Content: content },
  });
}

export async function deleteMessage(serverId, channelId, messageId) {
  await request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}`, { method: 'DELETE' });
}

export async function toggleReaction(serverId, channelId, messageId, emoji) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}/Reactions`, {
    method: 'POST',
    body: { Emoji: emoji },
  });
}

export async function pinMessage(serverId, channelId, messageId) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}:Pin`, { method: 'POST' });
}

export async function unpinMessage(serverId, channelId, messageId) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}:Unpin`, { method: 'POST' });
}

export async function getPinnedMessages(serverId, channelId) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/Pinned`);
}

export async function forwardMessage(serverId, channelId, messageId, { targetChannelId = null, targetConversationId = null }) {
  return request(`Servers/${serverId}/Channels/${channelId}/Messages/${messageId}/Forward`, {
    method: 'POST',
    body: { TargetChannelId: targetChannelId, TargetConversationId: targetConversationId },
  });
}
