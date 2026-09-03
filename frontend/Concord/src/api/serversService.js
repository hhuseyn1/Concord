import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function createServer({ Name, IconUrl = null }) {
  return request('Servers', { method: 'POST', body: { Name, IconUrl } });
}

export async function getMyServers() {
  return request('Servers');
}

export async function joinServer(inviteCode) {
  return request(`Servers/Join/${inviteCode}`, { method: 'POST' });
}

export async function updateServer(serverId, { Name, IconUrl = null }) {
  return request(`Servers/${serverId}`, { method: 'PUT', body: { Name, IconUrl } });
}

export async function leaveServer(serverId) {
  await request(`Servers/${serverId}/Members/Me`, { method: 'DELETE' });
}

export async function removeServerMember(serverId, userId) {
  await request(`Servers/${serverId}/Members/${userId}`, { method: 'DELETE' });
}

export async function deleteServer(serverId) {
  await request(`Servers/${serverId}`, { method: 'DELETE' });
}

export async function transferServerOwnership(serverId, newOwnerUserId) {
  await request(`Servers/${serverId}/Ownership/Transfer`, {
    method: 'POST',
    body: { NewOwnerUserId: newOwnerUserId },
  });
}

export async function getServerMembers(serverId, { page, pageSize } = {}) {
  return request(`Servers/${serverId}/Members`, { query: buildPagingQuery(page, pageSize) });
}

export async function createServerInvite(serverId, { ExpiresAtUtc = null, MaxUses = null } = {}) {
  return request(`Servers/${serverId}/Invites`, { method: 'POST', body: { ExpiresAtUtc, MaxUses } });
}

export async function listServerInvites(serverId) {
  return request(`Servers/${serverId}/Invites`);
}
