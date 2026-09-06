import { LogOut, Settings, ShieldCheck, Smile } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import * as sessionsService from '../../api/sessionsService'
import * as tokenStorage from '../../api/tokenStorage'
import { CustomStatusModal } from '../../features/settings/CustomStatusModal'
import { toAvatarPresence } from '../../features/friends/presence'
import { VoiceCallStrip } from '../../features/voice/VoiceCallStrip'
import { useAuth } from '../../hooks/useAuth'
import { usePresence } from '../../hooks/usePresence'
import { cn } from '../../lib/cn'
import { Avatar } from '../ui/Avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../ui/DropdownMenu'
import { IconButton } from '../ui/IconButton'
import { Skeleton } from '../ui/Skeleton'
import { Tooltip } from '../ui/Tooltip'

const STATUS_VALUES = [
  { value: 'Online', dotClassName: 'bg-presence-online' },
  { value: 'Idle', dotClassName: 'bg-presence-idle' },
  { value: 'DoNotDisturb', dotClassName: 'bg-presence-dnd' },
  { value: 'Invisible', dotClassName: 'bg-presence-offline' },
]

export function UserPanel({ className }) {
  const { t } = useTranslation()
  const { user, isLoading } = useAuth()
  const { status, setStatus } = usePresence()
  const [isSigningOut, setIsSigningOut] = useState(false)
  const [customStatusOpen, setCustomStatusOpen] = useState(false)

  const statusOptions = STATUS_VALUES.map((option) => ({
    ...option,
    label: t(`presence.${option.value === 'DoNotDisturb' ? 'doNotDisturb' : option.value.toLowerCase()}`),
  }))
  const hasCustomStatus = Boolean(user?.CustomStatusText)

  const handleSignOut = async () => {
    setIsSigningOut(true)
    try {
      await sessionsService.revokeCurrentSession()
    } catch (error) {
      console.error('Failed to revoke the current session', error)
    } finally {
      tokenStorage.clearTokens()
    }
  }

  return (
    <div className={cn('flex shrink-0 flex-col', className)}>
      <VoiceCallStrip />
      <div className="flex h-14 items-center gap-2 border-t border-border-subtle bg-surface-sidebar px-2">
        {isLoading ? (
          <>
            <Skeleton className="size-8 rounded-full" />
            <div className="min-w-0 flex-1">
              <Skeleton className="h-3 w-20" />
            </div>
          </>
        ) : (
          <>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <button
                  type="button"
                  aria-label={`Account menu (status: ${status})`}
                  className="shrink-0 rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
                >
                  <Avatar
                    src={user?.AvatarUrl ?? undefined}
                    name={user?.Username ?? user?.Name ?? undefined}
                    presence={toAvatarPresence(status)}
                    size="sm"
                  />
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" side="top">
                <DropdownMenuLabel>{t('presence.setStatus')}</DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuRadioGroup value={status} onValueChange={(next) => setStatus(next)}>
                  {statusOptions.map((option) => (
                    <DropdownMenuRadioItem key={option.value} value={option.value}>
                      <span className={cn('size-2 rounded-full', option.dotClassName)} aria-hidden="true" />
                      {option.label}
                    </DropdownMenuRadioItem>
                  ))}
                </DropdownMenuRadioGroup>
                <DropdownMenuSeparator />
                <DropdownMenuItem onSelect={() => setCustomStatusOpen(true)}>
                  <Smile className="size-4" aria-hidden="true" />
                  {t('customStatus.title')}
                </DropdownMenuItem>
                <DropdownMenuItem asChild>
                  <Link to="/cabinet/settings">
                    <Settings className="size-4" aria-hidden="true" />
                    Settings
                  </Link>
                </DropdownMenuItem>
                {user?.Role === 'Admin' && (
                  <DropdownMenuItem asChild>
                    <Link to="/cabinet/admin">
                      <ShieldCheck className="size-4" aria-hidden="true" />
                      {t('admin.dashboardLink')}
                    </Link>
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-fg-default">
                {user?.Username ||
                  [user?.Name, user?.Surname].filter(Boolean).join(' ') ||
                  'Not signed in'}
              </p>
              <p className="truncate text-xs text-fg-muted">
                {hasCustomStatus
                  ? `${user.CustomStatusEmoji ? `${user.CustomStatusEmoji} ` : ''}${user.CustomStatusText}`
                  : statusOptions.find((option) => option.value === status)?.label}
              </p>
            </div>
            <Tooltip content={t('settings.logout')} side="top">
              <IconButton
                aria-label={t('settings.logout')}
                variant="ghost"
                size="sm"
                disabled={isSigningOut}
                onClick={handleSignOut}
              >
                <LogOut className="size-4" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          </>
        )}
      </div>
      <CustomStatusModal open={customStatusOpen} onOpenChange={setCustomStatusOpen} />
    </div>
  )
}
