import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function createReport({ TargetType, TargetId, Reason }) {
  return request('Reports', { method: 'POST', body: { TargetType, TargetId, Reason } });
}

export async function getReports(page, pageSize, status, search, sortBy, sortDirection) {
  return request('Admin/Reports', {
    query: {
      ...buildPagingQuery(page, pageSize),
      status: status || undefined,
      search: search || undefined,
      sortBy: sortBy || undefined,
      sortDirection: sortDirection || undefined,
    },
  });
}

export async function resolveReport(reportId) {
  return request(`Admin/Reports/${reportId}:Resolve`, { method: 'POST' });
}

export async function dismissReport(reportId, reason) {
  return request(`Admin/Reports/${reportId}:Dismiss`, { method: 'POST', body: { Reason: reason || null } });
}
