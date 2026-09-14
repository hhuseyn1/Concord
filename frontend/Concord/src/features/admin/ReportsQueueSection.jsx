import { Flag } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { DataTable } from '../../components/ui/DataTable'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { toast } from '../../components/ui/Toast'
import { cn } from '../../lib/cn'
import { mapGetReportsError, mapReviewReportError } from '../moderation/reportsErrors'
import { useDismissReportMutation, useReportsQueue, useResolveReportMutation } from '../moderation/reportsQueries'
import { SortControls } from './SortControls'

const SEARCH_DEBOUNCE_MS = 300

const STATUS_OPTIONS = ['', 'Pending', 'Resolved', 'Dismissed']

const STATUS_BADGE_VARIANT = { Pending: 'warning', Resolved: 'success', Dismissed: 'neutral' }

const SORT_FIELDS = [
  { value: 'Reporter', label: 'admin.reportsSortReporter' },
  { value: 'Status', label: 'admin.reportsSortStatus' },
  { value: 'Created', label: 'admin.reportsSortCreated' },
]

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
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [sortBy, setSortBy] = useState(null)
  const [sortDirection, setSortDirection] = useState(null)
  const [dismissTarget, setDismissTarget] = useState(null)
  const [dismissReason, setDismissReason] = useState('')

  useEffect(() => {
    const handle = setTimeout(() => {
      setSearch(searchInput.trim())
      setPage(1)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [searchInput])

  const { data, isLoading, isFetching, isError, error } = useReportsQueue(page, status || undefined, search, sortBy, sortDirection)
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

  function handleSort(nextSortBy, nextSortDirection) {
    setSortBy(nextSortBy)
    setSortDirection(nextSortDirection)
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

  function handleDismissClick(report) {
    setDismissReason('')
    setDismissTarget(report)
  }

  async function handleDismissConfirm() {
    if (!dismissTarget) return
    try {
      await dismissMutation.mutateAsync({ reportId: dismissTarget.Id, reason: dismissReason || null })
      setDismissTarget(null)
      setDismissReason('')
      toast({ variant: 'success', title: t('admin.reportDismissed') })
    } catch (dismissError) {
      toast({ variant: 'danger', title: mapReviewReportError(dismissError) })
    }
  }

  const isReviewPending = resolveMutation.isPending || dismissMutation.isPending

  const columns = [
    {
      key: 'reporter',
      header: t('admin.reportColumnReporter'),
      render: (report) => {
        const reporterName =
          report.Reporter?.Username ||
          [report.Reporter?.Name, report.Reporter?.Surname].filter(Boolean).join(' ') ||
          t('common.unknownUser')
        return (
          <div className="flex items-center gap-2">
            <Avatar src={report.Reporter?.AvatarUrl ?? undefined} name={reporterName} size="sm" />
            <span className="font-medium text-fg-default">{reporterName}</span>
          </div>
        )
      },
    },
    {
      key: 'target',
      header: t('admin.reportColumnTarget'),
      cellClassName: 'max-w-[16rem] px-3 py-2 text-fg-muted',
      render: (report) => (
        <span className={cn('block truncate', !report.TargetSnippet && 'italic')} title={targetLabel(t, report)}>
          {targetLabel(t, report)}
        </span>
      ),
    },
    {
      key: 'reason',
      header: t('admin.reportColumnReason'),
      cellClassName: 'max-w-[20rem] px-3 py-2 text-fg-default',
      render: (report) => (
        <span className="block truncate" title={report.Reason}>
          {report.Reason}
        </span>
      ),
    },
    {
      key: 'status',
      header: t('admin.reportColumnStatus'),
      render: (report) => (
        <Badge variant={STATUS_BADGE_VARIANT[report.Status] ?? 'neutral'}>{t(`admin.reportStatus${report.Status}`)}</Badge>
      ),
    },
    {
      key: 'created',
      header: t('admin.reportColumnCreated'),
      cellClassName: 'px-3 py-2 whitespace-nowrap text-fg-muted',
      render: (report) => new Date(report.CreatedUtc).toLocaleString(),
    },
    {
      key: 'actions',
      header: t('admin.reportColumnActions'),
      render: (report) =>
        report.Status === 'Pending' ? (
          <div className="flex flex-wrap gap-2">
            <Button size="sm" variant="secondary" disabled={isReviewPending} onClick={() => handleResolve(report)}>
              {t('admin.resolve')}
            </Button>
            <Button size="sm" variant="ghost" disabled={isReviewPending} onClick={() => handleDismissClick(report)}>
              {t('admin.dismiss')}
            </Button>
          </div>
        ) : (
          <span className="text-xs text-fg-muted">-</span>
        ),
    },
  ]

  return (
    <div className="flex flex-col gap-3">
      <Input
        value={searchInput}
        onChange={(event) => setSearchInput(event.target.value)}
        placeholder={t('admin.reportsSearchPlaceholder')}
        className="max-w-xs"
        aria-label={t('admin.reportsSearchPlaceholder')}
      />

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

      <SortControls fields={SORT_FIELDS} sortBy={sortBy} sortDirection={sortDirection} onSort={handleSort} />

      <DataTable
        columns={columns}
        rows={reports}
        loading={isLoading}
        error={isError}
        errorTitle={t('admin.reportsLoadFailed')}
        errorDescription={mapGetReportsError(error)}
        emptyIcon={Flag}
        emptyTitle={t('admin.noReportsTitle')}
        emptyDescription={t('admin.noReportsDescription')}
        skeletonRowClassName="h-14 w-full rounded-md"
        page={page}
        totalPages={totalPages}
        totalCount={totalCount}
        isFetching={isFetching}
        onPageChange={setPage}
      />

      <Modal
        open={Boolean(dismissTarget)}
        onOpenChange={(open) => !open && setDismissTarget(null)}
        title={t('admin.dismissReportTitle')}
        description={t('admin.dismissReportDescription')}
        footer={
          <>
            <Button variant="ghost" onClick={() => setDismissTarget(null)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleDismissConfirm} disabled={dismissMutation.isPending}>
              {t('admin.dismiss')}
            </Button>
          </>
        }
      >
        <FormField label={t('admin.reportColumnReason')} hint={t('admin.dismissReasonHint')}>
          <Input value={dismissReason} onChange={(event) => setDismissReason(event.target.value)} maxLength={500} />
        </FormField>
      </Modal>
    </div>
  )
}
