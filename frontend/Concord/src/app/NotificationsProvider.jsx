import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useMemo, useRef } from 'react'
import i18n from '../i18n'
import * as directMessagesService from '../api/directMessagesService'
import * as usersService from '../api/usersService'
import { createNotificationsHub } from '../api/hubs/notificationsHub'
import { toast } from '../components/ui/Toast'
import { friendsKeys } from '../features/friends/friendsQueries'
import {
  flattenNotificationPages,
  notificationsKeys,
  useNotificationsList,
} from '../features/notifications/notificationsQueries'
import { jumpToMessage } from '../features/messages/jumpToMessage'
import { useAuth } from '../hooks/useAuth'
import { showDesktopNotification } from '../lib/desktopNotifications'
import { navigateTo } from '../lib/navigation'
import { playNotificationSound } from '../lib/notificationSound'
import { startTitleBlink } from '../lib/titleBlink'
import { NotificationsContext } from './NotificationsContext'

const TOAST_DESCRIPTION_KEY = {
  FriendRequestReceived: 'notifications.friendRequestReceived',
  FriendRequestAccepted: 'notifications.friendRequestAccepted',
  MissedCall: 'notifications.missedCallFrom',
  Mention: 'notifications.mentionedYou',
  DirectMessageReceived: 'notifications.sentYouAMessage',
}

const JUMP_AFTER_NAVIGATE_DELAY_MS = 400

function navigationForType(event) {
  if (event.type === 'FriendRequestReceived' || event.type === 'FriendRequestAccepted') {
    return () => navigateTo('/cabinet', { state: { tab: 'pending' } })
  }
  if ((event.type === 'Mention' || event.type === 'DirectMessageReceived') && event.contextMessageId) {
    return () => {
      const path = event.contextChannelId
        ? `/cabinet/servers/${event.contextServerId}/channels/${event.contextChannelId}`
        : `/cabinet/dm/${event.contextConversationId}`
      navigateTo(path)
      setTimeout(() => jumpToMessage(event.contextMessageId), JUMP_AFTER_NAVIGATE_DELAY_MS)
    }
  }
  return undefined
}

export function NotificationsProvider({ children }) {
  const { isAuthenticated, user } = useAuth()
  const queryClient = useQueryClient()
  const mutedRef = useRef(false)
  const soundEnabledRef = useRef(false)

  useEffect(() => {
    mutedRef.current = Boolean(user?.NotificationsMuted)
    soundEnabledRef.current = Boolean(user?.NotificationsSoundEnabled)
  }, [user?.NotificationsMuted, user?.NotificationsSoundEnabled])

  useEffect(() => {
    if (!isAuthenticated) return undefined

    const hub = createNotificationsHub()

    const unsubscribe = hub.onNotificationCreated((event) => {
      queryClient.invalidateQueries({ queryKey: notificationsKeys.all })
      if (event?.type === 'FriendRequestReceived' || event?.type === 'FriendRequestAccepted') {
        queryClient.invalidateQueries({ queryKey: friendsKeys.all })
      }

      if (mutedRef.current || !event?.type) return
      const descriptionKey = TOAST_DESCRIPTION_KEY[event.type]
      if (!descriptionKey) return

      usersService
        .getUserById(event.relatedUserId)
        .catch(() => null)
        .then((relatedUser) => {
          const name =
            relatedUser?.Username ||
            [relatedUser?.Name, relatedUser?.Surname].filter(Boolean).join(' ') ||
            'Someone'

          const handleClick =
            event.type === 'MissedCall'
              ? () =>
                  directMessagesService
                    .createOrGetConversation(event.relatedUserId)
                    .then((conversation) => navigateTo(`/cabinet/dm/${conversation.Id}`))
                    .catch(() => {})
              : navigationForType(event)

          const description = i18n.t(descriptionKey)

          if (soundEnabledRef.current) playNotificationSound()
          startTitleBlink(`${name} ${description}`)

          toast({
            variant: 'info',
            title: name,
            description,
            avatarSrc: relatedUser?.AvatarUrl ?? undefined,
            avatarName: name,
            onClick: handleClick,
            dedupeKey: `${event.type}:${event.relatedUserId}:${event.created}`,
          })

          showDesktopNotification({
            title: name,
            body: description,
            icon: relatedUser?.AvatarUrl ?? undefined,
            onClick: handleClick,
          })
        })
    })

    hub.start().catch((error) => {
      console.error('Failed to connect to the notifications hub', error)
    })

    return () => {
      unsubscribe()
      hub.stop().catch(() => {})
    }
  }, [isAuthenticated, queryClient])

  const { data } = useNotificationsList({ enabled: isAuthenticated })
  const unreadCount = useMemo(
    () => flattenNotificationPages(data?.pages).filter((item) => !item.IsRead).length,
    [data],
  )

  return <NotificationsContext.Provider value={{ unreadCount }}>{children}</NotificationsContext.Provider>
}
