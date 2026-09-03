import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as reportsService from '../../api/reportsService'

const REPORTS_PAGE_SIZE = 20

export const reportsKeys = {
  all: ['reports'],
  queue: (status) => [...reportsKeys.all, 'queue', status ?? 'all'],
}

export function useCreateReportMutation() {
  return useMutation({
    mutationFn: (data) => reportsService.createReport(data),
  })
}

export function useReportsQueue(page, status) {
  return useQuery({
    queryKey: [...reportsKeys.queue(status), page],
    queryFn: () => reportsService.getReports(page, REPORTS_PAGE_SIZE, status),
    placeholderData: (previousData) => previousData,
  })
}

export function useResolveReportMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (reportId) => reportsService.resolveReport(reportId),
    onSettled: () => queryClient.invalidateQueries({ queryKey: reportsKeys.all }),
  })
}

export function useDismissReportMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (reportId) => reportsService.dismissReport(reportId),
    onSettled: () => queryClient.invalidateQueries({ queryKey: reportsKeys.all }),
  })
}
