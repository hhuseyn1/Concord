import { ChevronDown, ChevronLeft, ChevronRight, ChevronUp, ScrollText } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Skeleton } from '../../components/ui/Skeleton'
import { mapAuditLogLoadError } from './adminErrors'
import { useAuditLog } from './auditLogQueries'

const SEARCH_DEBOUNCE_MS = 300

function formatAction(action) {
  if (!action) return action
  return action.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
}

function formatMetadata(metadata) {
  try {
    return JSON.stringify(JSON.parse(metadata), null, 2)
  } catch {
    return metadata
  }
}

function toUtcBound(dateValue, endOfDay) {
  if (!dateValue) return undefined
  return endOfDay ? `${dateValue}T23:59:59.999Z` : `${dateValue}T00:00:00.000Z`
}

function MetadataCell({ metadata }) {
  const { t } = useTranslation()
  const [expanded, setExpanded] = useState(false)

  if (!metadata) {
    return <span className="text-xs text-fg-muted">{t('admin.auditNoMetadata')}</span>
  }

  return (
    <div>
      <button
        type="button"
        onClick={() => setExpanded((current) => !current)}
        className="flex items-center gap-1 rounded-sm text-xs font-medium text-brand hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
      >
        {expanded ? <ChevronUp className="size-3.5" aria-hidden="true" /> : <ChevronDown className="size-3.5" aria-hidden="true" />}
        {expanded ? t('admin.auditHideMetadata') : t('admin.auditShowMetadata')}
      </button>
      {expanded && (
        <pre className="mt-1.5 max-w-md overflow-x-auto rounded-md border border-border-default bg-surface-sidebar p-2 text-xs whitespace-pre-wrap text-fg-default">
          {formatMetadata(metadata)}
        </pre>
      )}
    </div>
  )
}

export function AuditLogSection() {
  const { t } = useTranslation()

  const [actorInput, setActorInput] = useState('')
  const [actionInput, setActionInput] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [filters, setFilters] = useState({})
  const [page, setPage] = useState(1)

  useEffect(() => {
    const handle = setTimeout(() => {
      setFilters({
        actorUserId: actorInput.trim() || undefined,
        action: actionInput.trim() || undefined,
        fromUtc: toUtcBound(fromDate, false),
        toUtc: toUtcBound(toDate, true),
      })
      setPage(1)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [actorInput, actionInput, fromDate, toDate])

  const { data, isLoading, isFetching, isError, error } = useAuditLog(page, filters)

  const entries = data?.Items ?? []
  const totalCount = data?.TotalCount ?? 0
  const pageSize = data?.PageSize ?? 20
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))

  return (
    <div className="flex flex-col gap-3">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <FormField label={t('admin.auditFilterActor')}>
          <Input
            value={actorInput}
            onChange={(event) => setActorInput(event.target.value)}
            placeholder={t('admin.auditFilterActorPlaceholder')}
          />
        </FormField>
        <FormField label={t('admin.auditFilterAction')}>
          <Input
            value={actionInput}
            onChange={(event) => setActionInput(event.target.value)}
            placeholder={t('admin.auditFilterActionPlaceholder')}
          />
        </FormField>
        <FormField label={t('admin.auditFilterFrom')}>
          <Input type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />
        </FormField>
        <FormField label={t('admin.auditFilterTo')}>
          <Input type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />
        </FormField>
      </div>

      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 6 }, (_, index) => (
            <Skeleton key={index} className="h-12 w-full rounded-md" />
          ))}
        </div>
      )}

      {isError && <EmptyState title={t('admin.auditLogLoadFailed')} description={mapAuditLogLoadError(error)} />}

      {!isLoading && !isError && entries.length === 0 && (
        <EmptyState icon={ScrollText} title={t('admin.noAuditLogTitle')} description={t('admin.noAuditLogDescription')} />
      )}

      {!isLoading && !isError && entries.length > 0 && (
        <div className="overflow-x-auto rounded-md border border-border-default">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border-default bg-surface-sidebar text-xs text-fg-muted uppercase">
              <tr>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.auditColumnActor')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.auditColumnAction')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.auditColumnTarget')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.auditColumnTime')}</th>
                <th scope="col" className="px-3 py-2 font-semibold">{t('admin.auditColumnMetadata')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-default">
              {entries.map((entry) => {
                const actorName =
                  entry.Actor?.Username ||
                  [entry.Actor?.Name, entry.Actor?.Surname].filter(Boolean).join(' ') ||
                  t('common.unknownUser')

                return (
                  <tr key={entry.Id}>
                    <td className="px-3 py-2">
                      <div className="flex items-center gap-2">
                        <Avatar src={entry.Actor?.AvatarUrl ?? undefined} name={actorName} size="sm" />
                        <span className="font-medium text-fg-default">{actorName}</span>
                      </div>
                    </td>
                    <td className="px-3 py-2 text-fg-default">{formatAction(entry.Action)}</td>
                    <td className="px-3 py-2 text-fg-muted">
                      {entry.TargetType ? (
                        <span title={entry.TargetId ?? undefined}>
                          {entry.TargetType}
                          {entry.TargetId ? ` #${entry.TargetId.slice(0, 8)}` : ''}
                        </span>
                      ) : (
                        t('admin.auditNoTarget')
                      )}
                    </td>
                    <td className="px-3 py-2 whitespace-nowrap text-fg-muted">{new Date(entry.CreatedUtc).toLocaleString()}</td>
                    <td className="px-3 py-2">
                      <MetadataCell metadata={entry.Metadata} />
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
