import { useQuery } from '@tanstack/react-query'
import * as auditLogService from '../../api/auditLogService'

const AUDIT_LOG_PAGE_SIZE = 20

export const auditLogKeys = {
  all: ['auditLog'],
  list: (filters) => [...auditLogKeys.all, filters],
}

export function useAuditLog(page, filters) {
  return useQuery({
    queryKey: [...auditLogKeys.list(filters), page],
    queryFn: () =>
      auditLogService.getAuditLog(page, AUDIT_LOG_PAGE_SIZE, filters.actorUserId, filters.action, filters.fromUtc, filters.toUtc),
    placeholderData: (previousData) => previousData,
  })
}
