import { CreditCard, ExternalLink } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { DataTable } from '../../components/ui/DataTable'
import { Input } from '../../components/ui/Input'
import { cn } from '../../lib/cn'
import { mapSubscriptionsLoadError } from './adminErrors'
import { useAdminSubscriptions } from './adminQueries'
import { DateRangeFilter } from './DateRangeFilter'
import { SortControls } from './SortControls'

const SEARCH_DEBOUNCE_MS = 300

const STATUS_OPTIONS = ['', 'Active', 'PastDue', 'Canceled']

const STATUS_BADGE_VARIANT = { Active: 'success', PastDue: 'danger', Canceled: 'neutral' }

const SORT_FIELDS = [
  { value: 'Username', label: 'admin.paymentsSortUsername' },
  { value: 'Email', label: 'admin.paymentsSortEmail' },
  { value: 'Status', label: 'admin.paymentsSortStatus' },
  { value: 'CurrentPeriodEnd', label: 'admin.paymentsSortPeriodEnd' },
  { value: 'Created', label: 'admin.paymentsSortCreated' },
]

function toUtcBound(dateValue, endOfDay) {
  if (!dateValue) return undefined
  return endOfDay ? `${dateValue}T23:59:59.999Z` : `${dateValue}T00:00:00.000Z`
}

const selectClassName = cn(
  'h-9 rounded-md border border-border-default bg-surface-input px-3 text-base sm:text-sm text-fg-default',
  'outline-none focus-visible:border-brand focus-visible:ring-2 focus-visible:ring-brand',
)

function formatPeriodEnd(value) {
  if (!value) return null
  return new Date(value).toLocaleString(undefined, { dateStyle: 'medium' })
}

function stripeCustomerUrl(customerId) {
  return `https://dashboard.stripe.com/test/customers/${customerId}`
}

export function AdminPaymentsSection() {
  const { t } = useTranslation()
  const [status, setStatus] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [sortBy, setSortBy] = useState(null)
  const [sortDirection, setSortDirection] = useState(null)
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')

  useEffect(() => {
    const handle = setTimeout(() => {
      setSearch(searchInput.trim())
      setPage(1)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [searchInput])

  const fromUtc = toUtcBound(fromDate, false)
  const toUtc = toUtcBound(toDate, true)

  const { data, isLoading, isFetching, isError, error } = useAdminSubscriptions(
    page,
    status || undefined,
    search,
    sortBy,
    sortDirection,
    fromUtc,
    toUtc,
  )

  function handleDateRangeChange(nextFromDate, nextToDate) {
    setFromDate(nextFromDate)
    setToDate(nextToDate)
    setPage(1)
  }

  const subscriptions = data?.Items ?? []
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

  const columns = [
    {
      key: 'user',
      header: t('admin.paymentsColumnUser'),
      render: (row) => {
        const displayName = row.Username || t('common.unknownUser')
        return (
          <div className="flex items-center gap-2">
            <Avatar name={displayName} size="sm" />
            <div className="flex flex-col">
              <span className="font-medium text-fg-default">{displayName}</span>
              <span className="text-xs text-fg-muted">{row.Email}</span>
            </div>
          </div>
        )
      },
    },
    {
      key: 'status',
      header: t('admin.paymentsColumnStatus'),
      render: (row) => (
        <Badge variant={STATUS_BADGE_VARIANT[row.Status] ?? 'neutral'}>{t(`admin.paymentsStatus${row.Status}`)}</Badge>
      ),
    },
    {
      key: 'periodEnd',
      header: t('admin.paymentsColumnPeriodEnd'),
      cellClassName: 'px-3 py-2 whitespace-nowrap text-fg-muted',
      render: (row) => {
        const periodEnd = formatPeriodEnd(row.CurrentPeriodEnd)
        return (
          <div className="flex items-center gap-2">
            <span>{periodEnd ?? t('admin.paymentsNoPeriodEnd')}</span>
            {row.CancelAtPeriodEnd && <Badge variant="warning">{t('billing.endingBadge')}</Badge>}
          </div>
        )
      },
    },
    {
      key: 'stripe',
      header: t('admin.paymentsColumnStripe'),
      render: (row) =>
        row.StripeCustomerId ? (
          <a
            href={stripeCustomerUrl(row.StripeCustomerId)}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 text-sm font-medium text-brand hover:underline"
          >
            {t('admin.paymentsViewInStripe')}
            <ExternalLink className="size-3.5" aria-hidden="true" />
          </a>
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
        placeholder={t('admin.paymentsSearchPlaceholder')}
        className="max-w-xs"
        aria-label={t('admin.paymentsSearchPlaceholder')}
      />

      <select
        value={status}
        onChange={(event) => handleStatusChange(event.target.value)}
        className={cn(selectClassName, 'max-w-xs')}
        aria-label={t('admin.paymentsFilterStatus')}
      >
        {STATUS_OPTIONS.map((option) => (
          <option key={option || 'all'} value={option}>
            {t(option ? `admin.paymentsStatus${option}` : 'admin.paymentsStatusAll')}
          </option>
        ))}
      </select>

      <DateRangeFilter
        fromDate={fromDate}
        toDate={toDate}
        onChange={handleDateRangeChange}
        fromLabel={t('admin.paymentsFilterFrom')}
        toLabel={t('admin.paymentsFilterTo')}
      />

      <SortControls fields={SORT_FIELDS} sortBy={sortBy} sortDirection={sortDirection} onSort={handleSort} />

      <DataTable
        columns={columns}
        rows={subscriptions}
        loading={isLoading}
        error={isError}
        errorTitle={t('admin.paymentsLoadFailed')}
        errorDescription={mapSubscriptionsLoadError(error)}
        emptyIcon={CreditCard}
        emptyTitle={t('admin.noPaymentsTitle')}
        emptyDescription={t('admin.noPaymentsDescription')}
        page={page}
        totalPages={totalPages}
        totalCount={totalCount}
        isFetching={isFetching}
        onPageChange={setPage}
      />
    </div>
  )
}
