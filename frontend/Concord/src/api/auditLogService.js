import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getAuditLog(page, pageSize, actorEmail, action, fromUtc, toUtc, sortDirection) {
  return request('Admin/AuditLog', {
    query: {
      ...buildPagingQuery(page, pageSize),
      actorEmail: actorEmail || undefined,
      action: action || undefined,
      fromUtc: fromUtc || undefined,
      toUtc: toUtc || undefined,
      sortDirection: sortDirection || undefined,
    },
  });
}
