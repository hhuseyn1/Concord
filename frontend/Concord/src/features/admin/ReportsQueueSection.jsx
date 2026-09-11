import { ChevronLeft, ChevronRight, Flag } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { cn } from '../../lib/cn'
import { mapGetReportsError, mapReviewReportError } from '../moderation/reportsErrors'
import { useDismissReportMutation, useReportsQueue, useResolveReportMutation } from '../moderation/reportsQueries'

const STATUS_OPTIONS = ['', 'Pending', 'Resolved', 'Dismissed']

const STATUS_BADGE_VARIANT = { Pending: 'warning', Resolved: 'success', Dismissed: 'neutral' }

const selectClassName = cn(
  'h-9 rounded-md border border-border-default bg-surface-sidebar px-3 text-base sm:text-sm text-fg-default',
  'outline-none focus-visible:border-brand focus-visible:ring-2 focus-visible:ring-brand',
)

function targetLabel(t, report) {
  const typeLabel = t(report.TargetType === 'User' ? 'admin.targetTypeUser' : 'admin.targetTypeMessage')
  if (!report.TargetSnippet) {
    return `${typeLabel} - ${t('admin.targetDeleted')}`
  }
  return `${typeLabel} - ${report.TargetSnippet}`
}

export function ReportsQueueSection() {
  const { t } = useTranslation()
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading, isFetching, isError, error } = useReportsQueue(page, status || undefined)
  const resolveMutation = useResolveReportMutation()
  const dismissMutation = useDismissReportMutation()

  const reports = data?.Items ?? []
  const totalCount = data?.TotalCount ?? 0
  const pageSize = data?.PageSize ?? 20
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))

  function handleStatusChange(nextStatus) {
    setStatus(nextStatus)
    setPage(1)
  }

  async function handleResolve(report) {
    try {
      await resolveMutation.mutateAsync(report.Id)
      toast({ variant: 'success', title: t('admin.reportResolved') })
    } catch (resolveError) {
      toast({ variant: 'danger', title: mapReviewReportError(resolveError) })
    }
  }

  async function handleDismiss(report) {
    try {
      await dismissMutation.mutateAsync(report.Id)
      toast({ variant: 'success', title: t('admin.reportDismissed') })
    } catch (dismissError) {
      toast({ variant: 'danger', title: mapReviewReportError(dismissError) })
    }
  }

  const isReviewPending = resolveMutation.isPending || dismissMutation.isPending

  return (
    <div className="flex flex-col gap-3">
      <select
        value={status}
        onChange={(event) => handleStatusChange(event.target.value)}
        className={cn(selectClassName, 'max-w-xs')}
        aria-label={t('admin.reportColumnStatus')}
      >
        {STATUS_OPTIONS.map((option) => (
          <option key={option || 'all'} value={option}>
            {t(option ? `admin.reportStatus${option}` : 'admin.reportStatusAll')}
          </option>
        ))}
      </select>

      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 6 }, (_, index) => (
            <Skeleton key={index} className="h-14 w-full rounded-md" />
          ))}
        </div>
      )}

      {isError && <EmptyState title={t('admin.reportsLoadFailed')} description={mapGetReportsError(error)} />}

      {!isLoading && !isError && reports.length === 0 && (
        <EmptyState icon={Flag} title={t('admin.noReportsTitle')} description={t('admin.noReportsDescription')} />
      )}

      {!isLoading && !isError && reports.length > 0 && (
        <div className="overflow-x-auto rounded-md border border-border-default">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border-default bg-surface-sidebar text-xs text-fg-muted uppercase">
              <tr>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnReporter')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnTarget')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnReason')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnStatus')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnCreated')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.reportColumnActions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-default">
              {reports.map((report) => {
                const reporterName =
                  report.Reporter?.Username ||
                  [report.Reporter?.Name, report.Reporter?.Surname].filter(Boolean).join(' ') ||
                  t('common.unknownUser')

                return (
                  <tr key={report.Id}>
                    <td className="px-3 py-2">
                      <div className="flex items-center gap-2">
                        <Avatar src={report.Reporter?.AvatarUrl ?? undefined} name={reporterName} size="sm" />
                        <span className="font-medium text-fg-default">{reporterName}</span>
                      </div>
                    </td>
                    <td className="max-w-[16rem] px-3 py-2 text-fg-muted">
                      <span className={cn('block truncate', !report.TargetSnippet && 'italic')} title={targetLabel(t, report)}>
                        {targetLabel(t, report)}
                      </span>
                    </td>
                    <td className="max-w-[20rem] px-3 py-2 text-fg-default">
                      <span className="block truncate" title={report.Reason}>
                        {report.Reason}
                      </span>
                    </td>
                    <td className="px-3 py-2">
                      <Badge variant={STATUS_BADGE_VARIANT[report.Status] ?? 'neutral'}>
                        {t(`admin.reportStatus${report.Status}`)}
                      </Badge>
                    </td>
                    <td className="px-3 py-2 whitespace-nowrap text-fg-muted">{new Date(report.CreatedUtc).toLocaleString()}</td>
                    <td className="px-3 py-2">
                      {report.Status === 'Pending' ? (
                        <div className="flex flex-wrap gap-2">
                          <Button size="sm" variant="secondary" disabled={isReviewPending} onClick={() => handleResolve(report)}>
                            {t('admin.resolve')}
                          </Button>
                          <Button size="sm" variant="ghost" disabled={isReviewPending} onClick={() => handleDismiss(report)}>
                            {t('admin.dismiss')}
                          </Button>
                        </div>
                      ) : (
                        <span className="text-xs text-fg-muted">-</span>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {!isLoading && !isError && totalCount > 0 && (
        <div className="flex items-center justify-between text-sm text-fg-muted">
          <span>{t('admin.pageSummary', { page, totalPages, total: totalCount })}</span>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="secondary"
              disabled={page <= 1 || isFetching}
              onClick={() => setPage((current) => Math.max(1, current - 1))}
            >
              <ChevronLeft className="size-4" aria-hidden="true" />
              {t('admin.previous')}
            </Button>
            <Button
              size="sm"
              variant="secondary"
              disabled={page >= totalPages || isFetching}
              onClick={() => setPage((current) => current + 1)}
            >
              {t('admin.next')}
              <ChevronRight className="size-4" aria-hidden="true" />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
