import { useQuery } from '@tanstack/react-query'
import { Ban, Check, Flag, MessageCircle, UserMinus, UserPlus, X } from 'lucide-react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import * as directMessagesService from '../../api/directMessagesService'
import * as usersService from '../../api/usersService'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { mapCreateConversationError } from '../directMessages/directMessagesErrors'
import { toAvatarPresence } from '../friends/presence'
import { useRelationshipActions } from '../friends/useRelationshipActions'
import { ReportModal } from '../moderation/ReportModal'

const PRESENCE_BADGE_VARIANT = { Online: 'success', Idle: 'warning', DoNotDisturb: 'danger', Offline: 'neutral' }

export function ProfileCard({ userId }) {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { user: currentUser } = useAuth()
  const [confirmBlockOpen, setConfirmBlockOpen] = useState(false)
  const [isMessaging, setIsMessaging] = useState(false)
  const [reportOpen, setReportOpen] = useState(false)

  const {
    data: profile,
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ['users', userId],
    queryFn: () => usersService.getUserById(userId),
    enabled: Boolean(userId),
  })

  const { isPending, sendRequest, acceptRequest, declineRequest, cancelRequest, blockUser, unblockUser } =
    useRelationshipActions({ onChanged: refetch })

  const isSelf = Boolean(currentUser?.Id) && currentUser.Id === userId

  const handleConfirmBlock = async () => {
    setConfirmBlockOpen(false)
    await blockUser(profile)
  }

  const handleMessage = async () => {
    setIsMessaging(true)
    try {
      const conversation = await directMessagesService.createOrGetConversation(userId)
      navigate(`/cabinet/dm/${conversation.Id}`)
    } catch (messageError) {
      toast({ variant: 'danger', title: 'Could not open conversation', description: mapCreateConversationError(messageError) })
    } finally {
      setIsMessaging(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex flex-col gap-3 p-4">
        <div className="flex items-center gap-3">
          <Skeleton className="size-14 rounded-full" />
          <div className="flex flex-1 flex-col gap-1.5">
            <Skeleton className="h-4 w-24" />
            <Skeleton className="h-3 w-16" />
          </div>
        </div>
        <Skeleton className="h-8 w-full" />
      </div>
    )
  }

  if (isError || !profile) {
    return (
      <div className="p-2">
        <EmptyState
          title="Couldn't load profile"
          description={error?.message || 'Something went wrong.'}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              {t('common.tryAgain')}
            </Button>
          }
        />
      </div>
    )
  }

  const displayName =
    profile.Username || [profile.Name, profile.Surname].filter(Boolean).join(' ') || 'Unknown user'
  const fullName = [profile.Name, profile.Surname].filter(Boolean).join(' ')
  const pending = isPending(userId)

  return (
    <div className="flex flex-col gap-4 p-4">
      <Modal
        open={confirmBlockOpen}
        onOpenChange={setConfirmBlockOpen}
        title="Block this user?"
        description={`${displayName} will be removed from your friends (if you're friends) and won't be able to message you or see your profile.`}
        footer={
          <>
            <Button variant="ghost" onClick={() => setConfirmBlockOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="danger" onClick={handleConfirmBlock} disabled={pending}>
              Block User
            </Button>
          </>
        }
      />
      <ReportModal
        open={reportOpen}
        onOpenChange={setReportOpen}
        targetType="User"
        targetId={userId}
        title={t('reports.reportUserTitle', { name: displayName })}
        description={t('reports.reportUserDescription')}
      />
      <div className="flex items-center gap-3">
        <Avatar
          src={profile.AvatarUrl ?? undefined}
          name={displayName}
          presence={toAvatarPresence(profile.Status)}
          size="xl"
        />
        <div className="min-w-0 flex-1">
          <p className="truncate text-base font-semibold text-fg-heading">{displayName}</p>
          {fullName && fullName !== displayName && (
            <p className="truncate text-sm text-fg-muted">{fullName}</p>
          )}
          <Badge variant={PRESENCE_BADGE_VARIANT[profile.Status] ?? 'neutral'} className="mt-1">
            {t(`presence.${profile.Status === 'DoNotDisturb' ? 'doNotDisturb' : (profile.Status ?? 'offline').toLowerCase()}`)}
          </Badge>
        </div>
      </div>

      {profile.CustomStatusText && (
        <p className="truncate text-sm text-fg-default">
          {profile.CustomStatusEmoji ? `${profile.CustomStatusEmoji} ` : ''}
          {profile.CustomStatusText}
        </p>
      )}

      {profile.ActivityApplicationName && (
        <p className="truncate text-sm text-fg-default">
          {t(`activity.${profile.ActivityType?.toLowerCase() ?? 'using'}`, { app: profile.ActivityApplicationName })}
        </p>
      )}

      {!isSelf && profile.MutualFriendsCount > 0 && (
        <p className="text-xs text-fg-muted">
          {t('profile.mutualFriends', { count: profile.MutualFriendsCount })}
        </p>
      )}

      {isSelf ? (
        <p className="text-sm text-fg-muted">This is you.</p>
      ) : profile.RelationshipStatus === 'Blocked' ? (
        <div className="flex flex-col gap-2">
          <Badge variant="danger" className="w-fit">
            Blocked
          </Badge>
          <Button size="sm" variant="secondary" disabled={pending} onClick={() => unblockUser(profile)} className="w-fit">
            Unblock
          </Button>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          <Button size="sm" variant="secondary" disabled={isMessaging} onClick={handleMessage} className="w-fit">
            <MessageCircle className="size-4" aria-hidden="true" />
            {t('profile.message')}
          </Button>

          {profile.RelationshipStatus === 'Friends' && (
            <>
              <Badge variant="brand" className="w-fit">
                {t('friends.alreadyFriends')}
              </Badge>
              <Button size="sm" variant="secondary" disabled={pending} onClick={() => setConfirmBlockOpen(true)} className="w-fit">
                <Ban className="size-4" aria-hidden="true" />
                Block
              </Button>
            </>
          )}

          {profile.RelationshipStatus === 'IncomingRequest' && (
            <>
              <p className="text-sm text-fg-muted">Sent you a friend request.</p>
              <div className="flex gap-2">
                <Button size="sm" disabled={pending} onClick={() => acceptRequest(profile)}>
                  <Check className="size-4" aria-hidden="true" />
                  {t('friends.accept')}
                </Button>
                <Button size="sm" variant="secondary" disabled={pending} onClick={() => declineRequest(profile)}>
                  <X className="size-4" aria-hidden="true" />
                  {t('friends.decline')}
                </Button>
              </div>
            </>
          )}

          {profile.RelationshipStatus === 'OutgoingRequest' && (
            <>
              <Badge variant="neutral" className="w-fit">
                {t('friends.requestSent')}
              </Badge>
              <Button size="sm" variant="secondary" disabled={pending} onClick={() => cancelRequest(profile)}>
                <UserMinus className="size-4" aria-hidden="true" />
                Cancel request
              </Button>
            </>
          )}

          {profile.RelationshipStatus === 'None' && (
            <div className="flex gap-2">
              <Button size="sm" disabled={pending} onClick={() => sendRequest(profile)}>
                <UserPlus className="size-4" aria-hidden="true" />
                {t('friends.add')}
              </Button>
              <Button size="sm" variant="secondary" disabled={pending} onClick={() => setConfirmBlockOpen(true)}>
                <Ban className="size-4" aria-hidden="true" />
                Block
              </Button>
            </div>
          )}
        </div>
      )}

      {!isSelf && (
        <Button
          size="sm"
          variant="ghost"
          onClick={() => setReportOpen(true)}
          className="w-fit text-fg-muted hover:text-danger"
        >
          <Flag className="size-4" aria-hidden="true" />
          {t('reports.reportUser')}
        </Button>
      )}
    </div>
  )
}
