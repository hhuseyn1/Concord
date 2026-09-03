import { useTranslation } from 'react-i18next'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import { AdminOverviewSection } from './AdminOverviewSection'
import { AdminUsersTable } from './AdminUsersTable'
import { AuditLogSection } from './AuditLogSection'
import { ReportsQueueSection } from './ReportsQueueSection'

export function AdminDashboardScreen() {
  const { t } = useTranslation()
  const { user, isLoading } = useAuth()

  if (isLoading) return null

  if (user?.Role !== 'Admin') {
    return <Navigate to="/" replace />
  }

  return (
    <div className="flex flex-col gap-8 p-6">
      <div>
        <h1 className="text-xl font-semibold text-fg-heading">{t('admin.title')}</h1>
        <p className="text-sm text-fg-muted">{t('admin.subtitle')}</p>
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('admin.overview')}</h2>
        <AdminOverviewSection />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('admin.users')}</h2>
        <AdminUsersTable />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('admin.reportsQueue')}</h2>
        <ReportsQueueSection />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('admin.auditLog')}</h2>
        <AuditLogSection />
      </section>
    </div>
  )
}
