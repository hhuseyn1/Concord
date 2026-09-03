import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getAuditLog(page, pageSize, actorUserId, action, fromUtc, toUtc) {
  return request('Admin/AuditLog', {
    query: {
      ...buildPagingQuery(page, pageSize),
      actorUserId: actorUserId || undefined,
      action: action || undefined,
      fromUtc: fromUtc || undefined,
      toUtc: toUtc || undefined,
    },
  });
}
