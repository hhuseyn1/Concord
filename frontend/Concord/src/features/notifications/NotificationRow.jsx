import { Check, X } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { toast } from '../../components/ui/Toast'
import { cn } from '../../lib/cn'
import { mapRequestActionError } from '../friends/friendsErrors'
import {
  useAcceptFriendRequestMutation,
  useDeclineFriendRequestMutation,
  useIncomingRequests,
} from '../friends/friendsQueries'
import { jumpToMessage } from '../messages/jumpToMessage'
import { ProfilePopover } from '../members/ProfilePopover'
import { formatRelativeTime } from './formatRelativeTime'
import { useMarkNotificationReadMutation } from './notificationsQueries'

const TYPE_DESCRIPTION = {
  FriendRequestReceived: 'sent you a friend request',
  FriendRequestAccepted: 'accepted your friend request',
  MissedCall: 'missed your call',
  Mention: 'mentioned you',
  DirectMessageReceived: 'sent you a message',
}

const FRIEND_REQUEST_TYPES = new Set(['FriendRequestReceived', 'FriendRequestAccepted'])
const JUMP_AFTER_NAVIGATE_DELAY_MS = 400

export function NotificationRow({ notification, onNavigate }) {
  const navigate = useNavigate()
  const markReadMutation = useMarkNotificationReadMutation()
  const { data: incoming } = useIncomingRequests()
  const acceptMutation = useAcceptFriendRequestMutation()
  const declineMutation = useDeclineFriendRequestMutation()

  const relatedUser = notification.RelatedUser
  const displayName =
    relatedUser?.Username || [relatedUser?.Name, relatedUser?.Surname].filter(Boolean).join(' ') || 'Someone'
  const description = TYPE_DESCRIPTION[notification.Type] ?? 'sent you a notification'
  const isFriendRequestType = FRIEND_REQUEST_TYPES.has(notification.Type)

  const matchingRequest =
    notification.Type === 'FriendRequestReceived' && relatedUser?.Id
      ? incoming?.find((request) => request.User?.Id === relatedUser.Id)
      : undefined

  const markReadSafely = async () => {
    try {
      await markReadMutation.mutateAsync(notification.Id)
    } catch (markReadError) {
      toast({
        variant: 'danger',
        title: 'Could not mark as read',
        description: markReadError?.message || 'Something went wrong.',
      })
    }
  }

  const handleRowClick = () => {
    if (!notification.IsRead) markReadSafely()
    if (isFriendRequestType) {
      onNavigate?.()
      navigate('/cabinet', { state: { tab: 'pending' } })
    } else if (
      (notification.Type === 'Mention' || notification.Type === 'DirectMessageReceived') &&
      notification.ContextMessageId
    ) {
      onNavigate?.()
      const path = notification.ContextChannelId
        ? `/cabinet/servers/${notification.ContextServerId}/channels/${notification.ContextChannelId}`
        : `/cabinet/dm/${notification.ContextConversationId}`
      navigate(path)
      setTimeout(() => jumpToMessage(notification.ContextMessageId), JUMP_AFTER_NAVIGATE_DELAY_MS)
    }
  }

  const handleRowKeyDown = (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      handleRowClick()
    }
  }

  const handleAccept = async (event) => {
    event.stopPropagation()
    if (!matchingRequest) return
    try {
      await acceptMutation.mutateAsync(matchingRequest.Id)
      if (!notification.IsRead) markReadSafely()
      toast({
        variant: 'success',
        title: 'Friend request accepted',
        description: `You and ${displayName} are now friends.`,
      })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not accept request', description: mapRequestActionError(error) })
    }
  }

  const handleDecline = async (event) => {
    event.stopPropagation()
    if (!matchingRequest) return
    try {
      await declineMutation.mutateAsync(matchingRequest.Id)
      if (!notification.IsRead) markReadSafely()
      toast({ description: 'Friend request declined.' })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not decline request', description: mapRequestActionError(error) })
    }
  }

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={handleRowClick}
      onKeyDown={handleRowKeyDown}
      className={cn(
        'flex w-full items-start gap-3 rounded-md px-3 py-2 text-left transition-colors duration-150 hover:bg-fg-default/5',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
        !notification.IsRead && 'bg-brand-bg',
      )}
    >
      <span onClick={(event) => event.stopPropagation()} className="shrink-0">
        {relatedUser?.Id ? (
          <ProfilePopover userId={relatedUser.Id} side="left">
            <button type="button" className="block rounded-full" aria-label={`View ${displayName}'s profile`}>
              <Avatar src={relatedUser?.AvatarUrl ?? undefined} name={displayName} size="md" />
            </button>
          </ProfilePopover>
        ) : (
          <Avatar name={displayName} size="md" />
        )}
      </span>

      <div className="min-w-0 flex-1">
        <p className="text-sm text-fg-default">
          <span className="font-medium">{displayName}</span> {description}
        </p>
        <p className="mt-0.5 text-xs text-fg-muted">{formatRelativeTime(notification.Created)}</p>

        {matchingRequest && (
          <div className="mt-2 flex gap-2">
            <Button size="sm" disabled={acceptMutation.isPending} onClick={handleAccept}>
              <Check className="size-4" aria-hidden="true" />
              Accept
            </Button>
            <Button size="sm" variant="secondary" disabled={declineMutation.isPending} onClick={handleDecline}>
              <X className="size-4" aria-hidden="true" />
              Decline
            </Button>
          </div>
        )}
      </div>

      {!notification.IsRead && <span aria-hidden="true" className="mt-1.5 size-2 shrink-0 rounded-full bg-brand" />}
    </div>
  )
}
