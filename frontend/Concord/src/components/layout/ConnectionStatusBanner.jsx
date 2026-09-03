import { WifiOff } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { isAnyHubReconnecting, subscribeConnectionStatus } from '../../api/hubs/connectionStatusStore'

export function ConnectionStatusBanner() {
  const { t } = useTranslation()
  const [isReconnecting, setIsReconnecting] = useState(() => isAnyHubReconnecting())

  useEffect(() => subscribeConnectionStatus(setIsReconnecting), [])

  if (!isReconnecting) return null

  return (
    <div
      role="status"
      className="flex shrink-0 items-center justify-center gap-2 bg-warning-bg px-3 py-1.5 text-xs font-medium text-warning"
    >
      <WifiOff className="size-3.5 shrink-0 animate-pulse" aria-hidden="true" />
      {t('connection.reconnecting')}
    </div>
  )
}
