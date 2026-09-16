import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getOverview() {
  return request('Admin/Overview');
}

export async function getOverviewCharts(fromUtc, toUtc) {
  return request('Admin/Overview/Charts', {
    query: {
      fromUtc: fromUtc || undefined,
      toUtc: toUtc || undefined,
    },
  });
}

export async function getUserGrowth(year) {
  return request('Admin/Overview/UserGrowth', {
    query: {
      year: year || undefined,
    },
  });
}

export async function getUsers(page, pageSize, search, sortBy, sortDirection) {
  return request('Admin/Users', {
    query: {
      ...buildPagingQuery(page, pageSize),
      search: search || undefined,
      sortBy: sortBy || undefined,
      sortDirection: sortDirection || undefined,
    },
  });
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

export async function getSubscriptions(page, pageSize, status, search, sortBy, sortDirection, fromUtc, toUtc) {
  return request('Admin/Subscriptions', {
    query: {
      ...buildPagingQuery(page, pageSize),
      status: status || undefined,
      search: search || undefined,
      sortBy: sortBy || undefined,
      sortDirection: sortDirection || undefined,
      fromUtc: fromUtc || undefined,
      toUtc: toUtc || undefined,
    },
  });
}
