import { request } from './httpClient';

export async function getRoles(serverId) {
  return request(`Servers/${serverId}/Roles`);
}

export async function getMyPermissions(serverId) {
  return request(`Servers/${serverId}/Roles/Me`);
}

export async function createRole(serverId, { Name, Color = null, Permissions = 0 }) {
  return request(`Servers/${serverId}/Roles`, { method: 'POST', body: { Name, Color, Permissions } });
}

export async function updateRole(serverId, roleId, { Name, Color = null, Permissions = 0 }) {
  return request(`Servers/${serverId}/Roles/${roleId}`, { method: 'PUT', body: { Name, Color, Permissions } });
}

export async function deleteRole(serverId, roleId) {
  return request(`Servers/${serverId}/Roles/${roleId}`, { method: 'DELETE' });
}

export async function reorderRoles(serverId, roleIds) {
  return request(`Servers/${serverId}/Roles/Reorder`, { method: 'POST', body: { RoleIds: roleIds } });
}

export async function getMemberRoles(serverId, userId) {
  return request(`Servers/${serverId}/Members/${userId}/Roles`);
}

export async function assignRole(serverId, userId, roleId) {
  return request(`Servers/${serverId}/Members/${userId}/Roles/${roleId}`, { method: 'PUT' });
}

export async function removeRole(serverId, userId, roleId) {
  return request(`Servers/${serverId}/Members/${userId}/Roles/${roleId}`, { method: 'DELETE' });
}
