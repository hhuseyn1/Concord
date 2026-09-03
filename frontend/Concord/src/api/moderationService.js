import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getBans(serverId, page, pageSize) {
  return request(`Servers/${serverId}/Bans`, { query: buildPagingQuery(page, pageSize) });
}

export async function banMember(serverId, userId, { Reason = null, ExpiresAtUtc = null } = {}) {
  return request(`Servers/${serverId}/Bans/${userId}`, { method: 'PUT', body: { Reason, ExpiresAtUtc } });
}

export async function unbanUser(serverId, userId) {
  return request(`Servers/${serverId}/Bans/${userId}`, { method: 'DELETE' });
}

export async function getMemberModeration(serverId, userId) {
  return request(`Servers/${serverId}/Members/${userId}/Moderation`);
}

export async function muteMember(serverId, userId) {
  return request(`Servers/${serverId}/Members/${userId}/Mute`, { method: 'PUT' });
}

export async function unmuteMember(serverId, userId) {
  return request(`Servers/${serverId}/Members/${userId}/Mute`, { method: 'DELETE' });
}

export async function timeoutMember(serverId, userId, { DurationMinutes, Reason = null }) {
  return request(`Servers/${serverId}/Members/${userId}/Timeout`, {
    method: 'PUT',
    body: { DurationMinutes, Reason },
  });
}

export async function removeTimeout(serverId, userId) {
  return request(`Servers/${serverId}/Members/${userId}/Timeout`, { method: 'DELETE' });
}
