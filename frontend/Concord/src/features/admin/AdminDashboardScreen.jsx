import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../components/ui/Tabs'
import { AdminOverviewSection } from './AdminOverviewSection'
import { AdminPaymentsSection } from './AdminPaymentsSection'
import { AdminUsersTable } from './AdminUsersTable'
import { AuditLogSection } from './AuditLogSection'
import { ReportsQueueSection } from './ReportsQueueSection'

const DEFAULT_TAB = 'overview'

export function AdminDashboardScreen() {
  const { t } = useTranslation()
  const [tab, setTab] = useState(DEFAULT_TAB)

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-fg-heading">{t('admin.title')}</h1>
        <p className="text-sm text-fg-muted">{t('admin.subtitle')}</p>
      </div>

      <Tabs value={tab} onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="overview">{t('admin.overview')}</TabsTrigger>
          <TabsTrigger value="users">{t('admin.users')}</TabsTrigger>
          <TabsTrigger value="payments">{t('admin.payments')}</TabsTrigger>
          <TabsTrigger value="reports">{t('admin.reportsQueue')}</TabsTrigger>
          <TabsTrigger value="audit">{t('admin.auditLog')}</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <AdminOverviewSection />
        </TabsContent>
        <TabsContent value="users">
          <AdminUsersTable />
        </TabsContent>
        <TabsContent value="payments">
          <AdminPaymentsSection />
        </TabsContent>
        <TabsContent value="reports">
          <ReportsQueueSection />
        </TabsContent>
        <TabsContent value="audit">
          <AuditLogSection />
        </TabsContent>
      </Tabs>
    </div>
  )
}
