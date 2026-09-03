import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getOverview() {
  return request('Admin/Overview');
}

export async function getUsers(page, pageSize, search) {
  return request('Admin/Users', { query: { ...buildPagingQuery(page, pageSize), search: search || undefined } });
}

export async function disableUser(userId) {
  return request(`Admin/Users/${userId}/Disable`, { method: 'POST' });
}

export async function enableUser(userId) {
  return request(`Admin/Users/${userId}/Enable`, { method: 'POST' });
}

export async function setUserRole(userId, role) {
  return request(`Admin/Users/${userId}/Role`, { method: 'PUT', body: { Role: role } });
}
