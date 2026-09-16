import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { mapAdminLoadError } from './adminErrors'
import { useAdminOverview, useAdminOverviewCharts, useAdminUserGrowth } from './adminQueries'

// Mirrors AdminService's MinUserGrowthYear on the backend - just enough to keep the year steppers
// from wandering off into decades with no data rather than expressing a real product launch date.
const MIN_CHART_YEAR = 2000

// Full-year [from, to] UTC bounds for a calendar year, for charts that filter by year rather than
// an arbitrary date range (Admin/Overview/Charts still takes fromUtc/toUtc).
function yearUtcBounds(year) {
  return {
    fromUtc: `${year}-01-01T00:00:00.000Z`,
    toUtc: `${year}-12-31T23:59:59.999Z`,
  }
}

// Recharts sets `fill`/`stroke` as raw SVG presentation attributes (not a `style` property), and
// Chromium's paint step does not reliably resolve a `var(--x)` reference inside a presentation
// attribute value - the shape stays invisible even though getComputedStyle reports the color as
// resolved. Ticks/labels don't hit this (Recharts applies their `fill` via an inline `style`
// object, where var() works fine) - only mark colors (Bar `fill`, grid/axis `stroke`) need the
// value pre-resolved to a real color string. Re-read on a prefers-color-scheme change so charts
// still follow a live OS theme switch, the same as the rest of this CSS-var-driven app.
const CHART_COLOR_VARS = {
  brand: '--color-brand',
  success: '--color-success',
  danger: '--color-danger',
  borderDefault: '--color-border-default',
  borderSubtle: '--color-border-subtle',
  fgMuted: '--color-fg-muted',
  surfaceSidebar: '--color-surface-sidebar',
}

function readChartColors() {
  const styles = getComputedStyle(document.documentElement)
  return Object.fromEntries(
    Object.entries(CHART_COLOR_VARS).map(([key, varName]) => [key, styles.getPropertyValue(varName).trim()]),
  )
}

function useChartColors() {
  const [colors, setColors] = useState(readChartColors)

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = () => setColors(readChartColors())
    media.addEventListener('change', handleChange)
    return () => media.removeEventListener('change', handleChange)
  }, [])

  return colors
}

function formatMonthShort(dateString) {
  return new Date(`${dateString}T00:00:00Z`).toLocaleDateString(undefined, {
    month: 'short',
    timeZone: 'UTC',
  })
}

function formatMonthFull(dateString) {
  return new Date(`${dateString}T00:00:00Z`).toLocaleDateString(undefined, {
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  })
}

function ChartCard({ title, action, children }) {
  return (
    <div className="rounded-md border border-border-default bg-surface-sidebar p-4">
      <div className="mb-3 flex items-center justify-between gap-2">
        <p className="text-sm font-semibold text-fg-heading">{title}</p>
        {action}
      </div>
      {children}
    </div>
  )
}

// Prev/next year control shared by the overview charts, styled after DataTable's pagination
// Chevron buttons so admin-panel date navigation looks consistent.
function YearStepper({ year, onChange, minYear, maxYear }) {
  const { t } = useTranslation()

  return (
    <div className="flex items-center gap-1">
      <Button
        size="sm"
        variant="secondary"
        className="px-2"
        aria-label={t('admin.previousYear')}
        disabled={year <= minYear}
        onClick={() => onChange(year - 1)}
      >
        <ChevronLeft className="size-4" aria-hidden="true" />
      </Button>
      <span className="min-w-[4.5ch] text-center text-sm font-semibold text-fg-default">{year}</span>
      <Button
        size="sm"
        variant="secondary"
        className="px-2"
        aria-label={t('admin.nextYear')}
        disabled={year >= maxYear}
        onClick={() => onChange(year + 1)}
      >
        <ChevronRight className="size-4" aria-hidden="true" />
      </Button>
    </div>
  )
}

function StatTile({ label, value, tone = 'default' }) {
  const toneClass =
    tone === 'danger' ? 'text-danger' : tone === 'warning' ? 'text-warning' : tone === 'success' ? 'text-success' : 'text-fg-default'

  return (
    <div className="rounded-md border border-border-default bg-surface-sidebar px-4 py-3">
      <p className="text-xs text-fg-muted">{label}</p>
      <p className={`mt-1 text-2xl font-semibold ${toneClass}`}>{value}</p>
    </div>
  )
}

function UserGrowthChart({ growth, colors, year, onYearChange, maxYear, loading, isError, error }) {
  const { t } = useTranslation()
  const chartData = (growth ?? []).map((point) => ({ date: point.Date, count: point.Count }))
  const tickStyle = { fill: colors.fgMuted, fontSize: 12 }

  return (
    <ChartCard
      title={t('admin.userGrowthChartTitle')}
      action={<YearStepper year={year} onChange={onYearChange} minYear={MIN_CHART_YEAR} maxYear={maxYear} />}
    >
      {loading ? (
        <Skeleton className="h-60 rounded-md" />
      ) : isError ? (
        <EmptyState title={t('admin.overviewChartsLoadFailed')} description={mapAdminLoadError(error)} />
      ) : (
        <ResponsiveContainer width="100%" height={240}>
          <BarChart data={chartData} barCategoryGap="24%" margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
            <CartesianGrid stroke={colors.borderSubtle} vertical={false} />
            <XAxis
              dataKey="date"
              tickFormatter={formatMonthShort}
              tick={tickStyle}
              axisLine={{ stroke: colors.borderSubtle }}
              tickLine={false}
            />
            <YAxis allowDecimals={false} tick={tickStyle} axisLine={false} tickLine={false} width={32} />
            <Tooltip
              cursor={{ fill: colors.borderSubtle }}
              content={({ active, payload, label }) => {
                if (!active || !payload?.length) return null
                return (
                  <div className="rounded-md border border-border-default bg-surface-floating px-3 py-2 text-xs shadow-md">
                    <p className="font-medium text-fg-default">{formatMonthFull(label)}</p>
                    <p className="text-fg-muted">
                      {t('admin.userGrowthTooltipLabel')}: {payload[0].value}
                    </p>
                  </div>
                )
              }}
            />
            <Bar dataKey="count" name={t('admin.userGrowthTooltipLabel')} fill={colors.brand} radius={[4, 4, 0, 0]} maxBarSize={24} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </ChartCard>
  )
}

function SubscriptionsChart({ breakdown, colors, year, onYearChange, maxYear, loading, isError, error }) {
  const { t } = useTranslation()

  const segments = [
    { key: 'Active', label: t('admin.subscriptionsActive'), count: breakdown?.Active ?? 0, color: colors.success },
    { key: 'PastDue', label: t('admin.subscriptionsPastDue'), count: breakdown?.PastDue ?? 0, color: colors.danger },
    { key: 'Canceled', label: t('admin.subscriptionsCanceled'), count: breakdown?.Canceled ?? 0, color: colors.borderDefault },
  ]
  const total = segments.reduce((sum, segment) => sum + segment.count, 0)
  const lastNonZeroIndex = [...segments].reverse().findIndex((segment) => segment.count > 0)
  const lastNonZeroKey = lastNonZeroIndex === -1 ? null : segments[segments.length - 1 - lastNonZeroIndex].key

  const chartData =
    total > 0
      ? [Object.fromEntries([['name', 'subscriptions'], ...segments.map((segment) => [segment.key, segment.count])])]
      : [{ name: 'subscriptions', Empty: 1 }]

  return (
    <ChartCard
      title={t('admin.subscriptionsChartTitle')}
      action={<YearStepper year={year} onChange={onYearChange} minYear={MIN_CHART_YEAR} maxYear={maxYear} />}
    >
      {loading ? (
        <Skeleton className="h-24 rounded-md" />
      ) : isError ? (
        <EmptyState title={t('admin.overviewChartsLoadFailed')} description={mapAdminLoadError(error)} />
      ) : (
        <>
          <ResponsiveContainer width="100%" height={72}>
            <BarChart data={chartData} layout="vertical" margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
              <XAxis type="number" hide domain={[0, total > 0 ? total : 1]} />
              <YAxis type="category" dataKey="name" hide width={0} />
              {total > 0 && (
                <Tooltip
                  cursor={{ fill: colors.borderSubtle }}
                  content={({ active, payload }) => {
                    if (!active || !payload?.length) return null
                    return (
                      <div className="rounded-md border border-border-default bg-surface-floating px-3 py-2 text-xs shadow-md">
                        {payload.map((entry) => {
                          const segment = segments.find((candidate) => candidate.key === entry.dataKey)
                          if (!segment) return null
                          return (
                            <p key={entry.dataKey} className="text-fg-default">
                              {segment.label}: <span className="text-fg-muted">{segment.count}</span>
                            </p>
                          )
                        })}
                      </div>
                    )
                  }}
                />
              )}
              {total > 0 ? (
                segments.map((segment) => (
                  <Bar
                    key={segment.key}
                    dataKey={segment.key}
                    stackId="subscriptions"
                    name={segment.label}
                    fill={segment.color}
                    stroke={colors.surfaceSidebar}
                    strokeWidth={2}
                    radius={segment.key === lastNonZeroKey ? [0, 4, 4, 0] : [0, 0, 0, 0]}
                    barSize={24}
                  />
                ))
              ) : (
                <Bar dataKey="Empty" fill={colors.borderDefault} radius={[4, 4, 4, 4]} barSize={24} isAnimationActive={false} />
              )}
            </BarChart>
          </ResponsiveContainer>

          <div className="mt-3 flex flex-wrap gap-4 text-xs">
            {total > 0 ? (
              segments.map((segment) => (
                <div key={segment.key} className="flex items-center gap-1.5">
                  <span className="inline-block size-2.5 rounded-full" style={{ backgroundColor: segment.color }} aria-hidden="true" />
                  <span className="text-fg-default">{segment.label}</span>
                  <span className="text-fg-muted">— {segment.count}</span>
                </div>
              ))
            ) : (
              <span className="text-fg-muted">{t('admin.subscriptionsEmpty')}</span>
            )}
          </div>
        </>
      )}
    </ChartCard>
  )
}

export function AdminOverviewSection() {
  const { t } = useTranslation()
  const { data, isLoading, isError, error } = useAdminOverview()
  const colors = useChartColors()
  const currentYear = new Date().getUTCFullYear()

  const [growthYear, setGrowthYear] = useState(currentYear)
  const [subscriptionsYear, setSubscriptionsYear] = useState(currentYear)

  const { fromUtc, toUtc } = yearUtcBounds(subscriptionsYear)
  const {
    data: chartsData,
    isLoading: chartsLoading,
    isError: chartsIsError,
    error: chartsError,
  } = useAdminOverviewCharts(fromUtc, toUtc)

  const {
    data: userGrowth,
    isLoading: userGrowthLoading,
    isError: userGrowthIsError,
    error: userGrowthError,
  } = useAdminUserGrowth(growthYear)

  return (
    <div className="flex flex-col gap-4">
      {isLoading ? (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          {Array.from({ length: 10 }, (_, index) => (
            <Skeleton key={index} className="h-20 rounded-md" />
          ))}
        </div>
      ) : isError ? (
        <EmptyState title={t('admin.overviewLoadFailed')} description={mapAdminLoadError(error)} />
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          <StatTile label={t('admin.totalUsers')} value={data.TotalUsers} />
          <StatTile label={t('admin.disabledUsers')} value={data.DisabledUsers} tone={data.DisabledUsers > 0 ? 'warning' : 'default'} />
          <StatTile label={t('admin.totalServers')} value={data.TotalServers} />
          <StatTile label={t('admin.activeSessions')} value={data.ActiveSessions} />
          <StatTile label={t('admin.newUsers7d')} value={data.NewUsersLast7Days} tone="success" />
          <StatTile label={t('admin.totalMessages')} value={(data.TotalMessages + data.TotalDirectMessages).toLocaleString()} />
          <StatTile label={t('admin.twoFactorUsers')} value={data.TwoFactorEnabledUsers} tone="success" />
          <StatTile label={t('admin.activeBans')} value={data.ActiveBans} tone={data.ActiveBans > 0 ? 'danger' : 'default'} />
          <StatTile
            label={t('admin.activeTimeouts')}
            value={data.ActiveTimeouts}
            tone={data.ActiveTimeouts > 0 ? 'warning' : 'default'}
          />
          <StatTile label={t('admin.newServers7d')} value={data.NewServersLast7Days} tone="success" />
        </div>
      )}

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        <UserGrowthChart
          growth={userGrowth}
          colors={colors}
          year={growthYear}
          onYearChange={setGrowthYear}
          maxYear={currentYear}
          loading={userGrowthLoading}
          isError={userGrowthIsError}
          error={userGrowthError}
        />
        <SubscriptionsChart
          breakdown={chartsData?.SubscriptionsByStatus}
          colors={colors}
          year={subscriptionsYear}
          onYearChange={setSubscriptionsYear}
          maxYear={currentYear}
          loading={chartsLoading}
          isError={chartsIsError}
          error={chartsError}
        />
      </div>
    </div>
  )
}
