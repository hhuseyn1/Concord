import { request } from './httpClient';

export async function getChannels(serverId) {
  return request(`Servers/${serverId}/Channels`);
}

export async function createChannel(serverId, { Name, Type }) {
  return request(`Servers/${serverId}/Channels`, { method: 'POST', body: { Name, Type } });
}

export async function updateChannel(serverId, channelId, name) {
  return request(`Servers/${serverId}/Channels/${channelId}`, { method: 'PUT', body: { Name: name } });
}

export async function deleteChannel(serverId, channelId) {
  await request(`Servers/${serverId}/Channels/${channelId}`, { method: 'DELETE' });
}
