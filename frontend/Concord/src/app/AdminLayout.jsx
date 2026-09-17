import { ArrowLeft } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link, Outlet } from 'react-router-dom'

export function AdminLayout() {
  const { t } = useTranslation()

  return (
    <div className="min-h-dvh bg-surface-base">
      <header className="flex h-14 shrink-0 items-center justify-between border-b border-border-subtle bg-surface-sidebar px-4 sm:px-6">
        <div className="flex items-center gap-2">
          <img src="/logo-app-icon.png" alt="" className="size-8 shrink-0 rounded-lg" aria-hidden="true" />
          <span className="text-sm font-semibold text-fg-heading">Concord</span>
        </div>
        <Link
          to="/cabinet"
          className="flex items-center gap-1.5 rounded-sm text-sm font-medium text-fg-muted transition-colors hover:text-fg-default focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          {t('admin.backToApp')}
        </Link>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6 sm:px-6">
        <Outlet />
      </main>
    </div>
  )
}
