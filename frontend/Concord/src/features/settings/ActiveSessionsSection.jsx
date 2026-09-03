import { LogOut, Monitor, Smartphone } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { formatRelativeTime } from '../notifications/formatRelativeTime'
import { mapSessionActionError } from './settingsErrors'
import { useRevokeOtherSessionsMutation, useRevokeSessionMutation, useSessionsList } from './settingsQueries'

const MOBILE_OS_HINTS = ['ios', 'android']

function DeviceIcon({ os }) {
  const isMobile = os && MOBILE_OS_HINTS.some((hint) => os.toLowerCase().includes(hint))
  const Icon = isMobile ? Smartphone : Monitor
  return <Icon className="size-5 shrink-0 text-fg-muted" aria-hidden="true" />
}

export function ActiveSessionsSection() {
  const { t } = useTranslation()
  const { data: sessions, isLoading, isError, error, refetch } = useSessionsList()
  const revokeMutation = useRevokeSessionMutation()
  const revokeOthersMutation = useRevokeOtherSessionsMutation()
  const [confirmSession, setConfirmSession] = useState(null)
  const [confirmAllOpen, setConfirmAllOpen] = useState(false)

  const otherSessionsCount = (sessions ?? []).filter((session) => !session.IsCurrent).length

  const handleRevoke = async (session) => {
    try {
      await revokeMutation.mutateAsync(session.Id)
      toast({ variant: 'success', description: 'That device has been signed out.' })
    } catch (revokeError) {
      toast({ variant: 'danger', title: 'Could not sign out that device', description: mapSessionActionError(revokeError) })
    } finally {
      setConfirmSession(null)
    }
  }

  const handleRevokeAllOthers = async () => {
    try {
      await revokeOthersMutation.mutateAsync()
      toast({ variant: 'success', description: 'All other devices have been signed out.' })
    } catch (revokeError) {
      toast({ variant: 'danger', title: 'Could not sign out other devices', description: mapSessionActionError(revokeError) })
    } finally {
      setConfirmAllOpen(false)
    }
  }

  return (
    <div className="flex max-w-md flex-col gap-3">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('settings.activeSessions')}</h2>
        {otherSessionsCount > 0 && (
          <Button size="sm" variant="secondary" onClick={() => setConfirmAllOpen(true)}>
            <LogOut className="size-4" aria-hidden="true" />
            {t('settings.logoutAllOtherSessions')}
          </Button>
        )}
      </div>

      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 2 }, (_, index) => (
            <div key={index} className="flex items-center gap-3 rounded-md border border-border-subtle p-3">
              <Skeleton className="size-5 rounded-full" />
              <Skeleton className="h-4 w-40" />
            </div>
          ))}
        </div>
      )}

      {isError && (
        <EmptyState
          title="Couldn't load your sessions"
          description={error?.message || 'Something went wrong.'}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              {t('common.tryAgain')}
            </Button>
          }
        />
      )}

      {!isLoading && !isError && (sessions ?? []).length === 0 && (
        <p className="text-sm text-fg-muted">{t('sessions.noOtherSessions')}</p>
      )}

      {!isLoading && !isError && (sessions ?? []).length > 0 && (
        <div className="flex flex-col gap-2">
          {sessions.map((session) => (
            <div
              key={session.Id}
              className="flex items-center gap-3 rounded-md border border-border-subtle p-3"
            >
              <DeviceIcon os={session.OS} />
              <div className="min-w-0 flex-1">
                <p className="flex items-center gap-2 truncate text-sm font-medium text-fg-default">
                  {session.DeviceLabel || t('sessions.unknownDevice')}
                  {session.IsCurrent && <Badge variant="brand">{t('sessions.thisDevice')}</Badge>}
                </p>
                <p className="truncate text-xs text-fg-muted">
                  {t('sessions.lastActive')} {formatRelativeTime(session.LastActiveAt)}
                  {session.IpAddress ? ` · ${session.IpAddress}` : ''}
                </p>
              </div>
              {!session.IsCurrent && (
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={revokeMutation.isPending}
                  onClick={() => setConfirmSession(session)}
                >
                  {t('sessions.revoke')}
                </Button>
              )}
            </div>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(confirmSession)}
        onOpenChange={(open) => !open && setConfirmSession(null)}
        title={t('sessions.revokeConfirmTitle')}
        description={t('sessions.revokeConfirmDescription')}
        footer={
          <>
            <Button variant="secondary" onClick={() => setConfirmSession(null)}>
              {t('common.cancel')}
            </Button>
            <Button variant="danger" disabled={revokeMutation.isPending} onClick={() => handleRevoke(confirmSession)}>
              {revokeMutation.isPending && <Spinner size="sm" />}
              {t('sessions.revoke')}
            </Button>
          </>
        }
      />

      <Modal
        open={confirmAllOpen}
        onOpenChange={setConfirmAllOpen}
        title={t('sessions.revokeAllOthersConfirmTitle')}
        description={t('sessions.revokeAllOthersConfirmDescription')}
        footer={
          <>
            <Button variant="secondary" onClick={() => setConfirmAllOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="danger" disabled={revokeOthersMutation.isPending} onClick={handleRevokeAllOthers}>
              {revokeOthersMutation.isPending && <Spinner size="sm" />}
              {t('settings.logoutAllOtherSessions')}
            </Button>
          </>
        }
      />
    </div>
  )
}
