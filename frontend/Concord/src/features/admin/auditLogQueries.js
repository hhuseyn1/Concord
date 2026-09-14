import { useQuery } from '@tanstack/react-query'
import * as auditLogService from '../../api/auditLogService'

const AUDIT_LOG_PAGE_SIZE = 20

export const auditLogKeys = {
  all: ['auditLog'],
  list: (filters, sortDirection) => [...auditLogKeys.all, filters, sortDirection ?? ''],
}

export function useAuditLog(page, filters, sortDirection) {
  return useQuery({
    queryKey: [...auditLogKeys.list(filters, sortDirection), page],
    queryFn: () =>
      auditLogService.getAuditLog(
        page,
        AUDIT_LOG_PAGE_SIZE,
        filters.actorEmail,
        filters.action,
        filters.fromUtc,
        filters.toUtc,
        sortDirection,
      ),
    placeholderData: (previousData) => previousData,
  })
}
