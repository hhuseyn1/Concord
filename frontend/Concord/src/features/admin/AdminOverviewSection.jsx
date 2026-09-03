import { useTranslation } from 'react-i18next'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { mapAdminLoadError } from './adminErrors'
import { useAdminOverview } from './adminQueries'

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

export function AdminOverviewSection() {
  const { t } = useTranslation()
  const { data, isLoading, isError, error } = useAdminOverview()

  if (isLoading) {
    return (
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {Array.from({ length: 10 }, (_, index) => (
          <Skeleton key={index} className="h-20 rounded-md" />
        ))}
      </div>
    )
  }

  if (isError) {
    return <EmptyState title={t('admin.overviewLoadFailed')} description={mapAdminLoadError(error)} />
  }

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      <StatTile label={t('admin.totalUsers')} value={data.TotalUsers} />
      <StatTile label={t('admin.disabledUsers')} value={data.DisabledUsers} tone={data.DisabledUsers > 0 ? 'warning' : 'default'} />
      <StatTile label={t('admin.totalServers')} value={data.TotalServers} />
      <StatTile label={t('admin.activeSessions')} value={data.ActiveSessions} />
      <StatTile label={t('admin.newUsers7d')} value={data.NewUsersLast7Days} tone="success" />
      <StatTile label={t('admin.totalMessages')} value={(data.TotalMessages + data.TotalDirectMessages).toLocaleString()} />
      <StatTile label={t('admin.twoFactorUsers')} value={data.TwoFactorEnabledUsers} tone="success" />
      <StatTile label={t('admin.activeBans')} value={data.ActiveBans} tone={data.ActiveBans > 0 ? 'danger' : 'default'} />
      <StatTile label={t('admin.activeTimeouts')} value={data.ActiveTimeouts} tone={data.ActiveTimeouts > 0 ? 'warning' : 'default'} />
      <StatTile label={t('admin.newServers7d')} value={data.NewServersLast7Days} tone="success" />
    </div>
  )
}
