import { ChevronDown, ChevronUp, ScrollText } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { DataTable } from '../../components/ui/DataTable'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { formatAction } from './adminFormatters'
import { mapAuditLogLoadError } from './adminErrors'
import { useAuditLog } from './auditLogQueries'
import { SortControls } from './SortControls'

const SEARCH_DEBOUNCE_MS = 300

const SORT_FIELDS = [{ value: 'Created', label: 'admin.auditSortCreated' }]

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
  const [sortBy, setSortBy] = useState(null)
  const [sortDirection, setSortDirection] = useState(null)

  useEffect(() => {
    const handle = setTimeout(() => {
      setFilters({
        actorEmail: actorInput.trim() || undefined,
        action: actionInput.trim() || undefined,
        fromUtc: toUtcBound(fromDate, false),
        toUtc: toUtcBound(toDate, true),
      })
      setPage(1)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [actorInput, actionInput, fromDate, toDate])

  function handleSort(nextSortBy, nextSortDirection) {
    setSortBy(nextSortBy)
    setSortDirection(nextSortDirection)
    setPage(1)
  }

  const { data, isLoading, isFetching, isError, error } = useAuditLog(page, filters, sortDirection)

  const entries = data?.Items ?? []
  const totalCount = data?.TotalCount ?? 0
  const pageSize = data?.PageSize ?? 20
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))

  const columns = [
    {
      key: 'actor',
      header: t('admin.auditColumnActor'),
      render: (entry) => {
        const actorName =
          entry.Actor?.Username ||
          [entry.Actor?.Name, entry.Actor?.Surname].filter(Boolean).join(' ') ||
          t('common.unknownUser')
        return (
          <div className="flex items-center gap-2">
            <Avatar src={entry.Actor?.AvatarUrl ?? undefined} name={actorName} size="sm" />
            <span className="font-medium text-fg-default">{actorName}</span>
          </div>
        )
      },
    },
    {
      key: 'action',
      header: t('admin.auditColumnAction'),
      cellClassName: 'px-3 py-2 text-fg-default',
      render: (entry) => formatAction(entry.Action),
    },
    {
      key: 'target',
      header: t('admin.auditColumnTarget'),
      cellClassName: 'px-3 py-2 text-fg-muted',
      render: (entry) =>
        entry.TargetType ? (
          <span title={entry.TargetId ?? undefined}>
            {entry.TargetType}
            {entry.TargetId ? ` #${entry.TargetId.slice(0, 8)}` : ''}
          </span>
        ) : (
          t('admin.auditNoTarget')
        ),
    },
    {
      key: 'time',
      header: t('admin.auditColumnTime'),
      cellClassName: 'px-3 py-2 whitespace-nowrap text-fg-muted',
      render: (entry) => new Date(entry.CreatedUtc).toLocaleString(),
    },
    {
      key: 'metadata',
      header: t('admin.auditColumnMetadata'),
      render: (entry) => <MetadataCell metadata={entry.Metadata} />,
    },
  ]

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

      <SortControls fields={SORT_FIELDS} sortBy={sortBy} sortDirection={sortDirection} onSort={handleSort} />

      <DataTable
        columns={columns}
        rows={entries}
        loading={isLoading}
        error={isError}
        errorTitle={t('admin.auditLogLoadFailed')}
        errorDescription={mapAuditLogLoadError(error)}
        emptyIcon={ScrollText}
        emptyTitle={t('admin.noAuditLogTitle')}
        emptyDescription={t('admin.noAuditLogDescription')}
        page={page}
        totalPages={totalPages}
        totalCount={totalCount}
        isFetching={isFetching}
        onPageChange={setPage}
      />
    </div>
  )
}
