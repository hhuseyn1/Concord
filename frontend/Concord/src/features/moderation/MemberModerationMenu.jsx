import { Ban, Clock, MicOff, MoreVertical, UserMinus, Volume2 } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { FormField } from '../../components/ui/FormField'
import { IconButton } from '../../components/ui/IconButton'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { toast } from '../../components/ui/Toast'
import { Tooltip } from '../../components/ui/Tooltip'
import { useCan } from '../roles/rolesQueries'
import { mapBanMemberError, mapMuteMemberError, mapTimeoutMemberError } from './moderationErrors'
import { useBanMemberMutation, useRemoveTimeoutMutation, useSetMuteMutation, useTimeoutMemberMutation } from './moderationQueries'

const TIMEOUT_PRESETS = [5, 60, 24 * 60, 7 * 24 * 60]

export function MemberModerationMenu({ serverId, member, isSelf, isTargetOwner, onKick, canKick }) {
  const { t } = useTranslation()
  const { can } = useCan(serverId)

  const [timeoutOpen, setTimeoutOpen] = useState(false)
  const [banOpen, setBanOpen] = useState(false)
  const [timeoutMinutes, setTimeoutMinutes] = useState(TIMEOUT_PRESETS[1])
  const [reason, setReason] = useState('')

  const setMuteMutation = useSetMuteMutation(serverId)
  const timeoutMutation = useTimeoutMemberMutation(serverId)
  const removeTimeoutMutation = useRemoveTimeoutMutation(serverId)
  const banMutation = useBanMemberMutation(serverId)

  const userId = member?.User?.Id
  const displayName =
    member?.User?.Username ||
    [member?.User?.Name, member?.User?.Surname].filter(Boolean).join(' ') ||
    t('common.unknownUser')

  const canMute = can('MuteMembers')
  const canTimeout = can('ModerateMembers')
  const canBan = can('BanMembers')

  const actionable = !isSelf && !isTargetOwner
  const hasAnyAction = canMute || canTimeout || canBan || canKick

  if (!hasAnyAction || !actionable || !userId) return null

  const isMuted = Boolean(member.IsMuted)
  const isTimedOut = Boolean(member.TimedOutUntil) && new Date(member.TimedOutUntil) > new Date()

  async function handleMuteToggle() {
    try {
      await setMuteMutation.mutateAsync({ userId, muted: !isMuted })
      toast({ variant: 'success', title: isMuted ? t('moderation.unmuted', { name: displayName }) : t('moderation.muted', { name: displayName }) })
    } catch (error) {
      toast({ variant: 'danger', title: mapMuteMemberError(error) })
    }
  }

  async function handleRemoveTimeout() {
    try {
      await removeTimeoutMutation.mutateAsync(userId)
      toast({ variant: 'success', title: t('moderation.timeoutLifted', { name: displayName }) })
    } catch (error) {
      toast({ variant: 'danger', title: mapTimeoutMemberError(error) })
    }
  }

  async function handleTimeout() {
    try {
      await timeoutMutation.mutateAsync({ userId, DurationMinutes: timeoutMinutes, Reason: reason || null })
      setTimeoutOpen(false)
      setReason('')
      toast({ variant: 'success', title: t('moderation.timedOut', { name: displayName }) })
    } catch (error) {
      toast({ variant: 'danger', title: mapTimeoutMemberError(error) })
    }
  }

  async function handleBan() {
    try {
      await banMutation.mutateAsync({ userId, Reason: reason || null })
      setBanOpen(false)
      setReason('')
      toast({ variant: 'success', title: t('moderation.banned', { name: displayName }) })
    } catch (error) {
      toast({ variant: 'danger', title: mapBanMemberError(error) })
    }
  }

  return (
    <>
      <DropdownMenu>
        <Tooltip content={t('moderation.actions')}>
          <DropdownMenuTrigger asChild>
            <IconButton aria-label={t('moderation.actionsFor', { name: displayName })} variant="ghost" size="sm">
              <MoreVertical className="size-3.5" aria-hidden="true" />
            </IconButton>
          </DropdownMenuTrigger>
        </Tooltip>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>{displayName}</DropdownMenuLabel>
          <DropdownMenuSeparator />

          {canMute && (
            <DropdownMenuItem onSelect={handleMuteToggle}>
              {isMuted ? <Volume2 className="size-4" aria-hidden="true" /> : <MicOff className="size-4" aria-hidden="true" />}
              {isMuted ? t('moderation.unmute') : t('moderation.mute')}
            </DropdownMenuItem>
          )}

          {canTimeout && (
            <DropdownMenuItem onSelect={() => (isTimedOut ? handleRemoveTimeout() : setTimeoutOpen(true))}>
              <Clock className="size-4" aria-hidden="true" />
              {isTimedOut ? t('moderation.removeTimeout') : t('moderation.timeout')}
            </DropdownMenuItem>
          )}

          {(canKick || canBan) && <DropdownMenuSeparator />}

          {canKick && (
            <DropdownMenuItem danger onSelect={onKick}>
              <UserMinus className="size-4" aria-hidden="true" />
              {t('moderation.kick')}
            </DropdownMenuItem>
          )}

          {canBan && (
            <DropdownMenuItem danger onSelect={() => setBanOpen(true)}>
              <Ban className="size-4" aria-hidden="true" />
              {t('moderation.ban')}
            </DropdownMenuItem>
          )}
        </DropdownMenuContent>
      </DropdownMenu>

      <Modal
        open={timeoutOpen}
        onOpenChange={setTimeoutOpen}
        title={t('moderation.timeoutTitle', { name: displayName })}
        description={t('moderation.timeoutDescription')}
        footer={
          <>
            <Button variant="ghost" onClick={() => setTimeoutOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleTimeout} disabled={timeoutMutation.isPending}>
              {t('moderation.timeout')}
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-3">
          <FormField label={t('moderation.duration')}>
            <div className="flex flex-wrap gap-2">
              {TIMEOUT_PRESETS.map((minutes) => (
                <Button
                  key={minutes}
                  size="sm"
                  variant={timeoutMinutes === minutes ? 'primary' : 'secondary'}
                  onClick={() => setTimeoutMinutes(minutes)}
                >
                  {t(`moderation.preset.${minutes}`)}
                </Button>
              ))}
            </div>
          </FormField>
          <FormField label={t('moderation.reason')} hint={t('moderation.reasonOptional')}>
            <Input value={reason} onChange={(event) => setReason(event.target.value)} maxLength={500} />
          </FormField>
        </div>
      </Modal>

      <Modal
        open={banOpen}
        onOpenChange={setBanOpen}
        title={t('moderation.banTitle', { name: displayName })}
        description={t('moderation.banDescription')}
        footer={
          <>
            <Button variant="ghost" onClick={() => setBanOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="danger" onClick={handleBan} disabled={banMutation.isPending}>
              {t('moderation.ban')}
            </Button>
          </>
        }
      >
        <FormField label={t('moderation.reason')} hint={t('moderation.reasonOptional')}>
          <Input value={reason} onChange={(event) => setReason(event.target.value)} maxLength={500} />
        </FormField>
      </Modal>
    </>
  )
}
