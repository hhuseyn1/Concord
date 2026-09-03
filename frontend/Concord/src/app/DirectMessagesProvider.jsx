import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { createDirectMessagesHub } from '../api/hubs/directMessagesHub'
import { toast } from '../components/ui/Toast'
import { directMessagesCache, directMessagesKeys } from '../features/directMessages/directMessagesQueries'
import { useAuth } from '../hooks/useAuth'
import { showDesktopNotification } from '../lib/desktopNotifications'
import { navigateTo } from '../lib/navigation'
import { DirectMessagesContext } from './DirectMessagesContext'

const TYPING_EXPIRY_MS = 6000

export function DirectMessagesProvider({ children }) {
  const { isAuthenticated, user } = useAuth()
  const queryClient = useQueryClient()
  const hubRef = useRef(null)
  const typingTimeoutsRef = useRef(new Map())
  const [typingByConversation, setTypingByConversation] = useState({})
  const [readReceiptsByConversation, setReadReceiptsByConversation] = useState({})
  const mutedRef = useRef(false)
  const userIdRef = useRef(undefined)

  useEffect(() => {
    mutedRef.current = Boolean(user?.NotificationsMuted)
    userIdRef.current = user?.Id
  }, [user?.NotificationsMuted, user?.Id])

  useEffect(() => {
    if (!isAuthenticated) return undefined

    const hub = createDirectMessagesHub()
    hubRef.current = hub
    const timeouts = typingTimeoutsRef.current

    const isConversationOpen = (conversationId) => window.location.pathname === `/dm/${conversationId}`

    const unsubscribeReceived = hub.onDirectMessageReceived((message) => {
      const conversationOpen = isConversationOpen(message.ConversationId)
      directMessagesCache.patchConversationsList(queryClient, message, {
        skipUnreadBump: conversationOpen,
      })
      if (queryClient.getQueryData(directMessagesKeys.list(message.ConversationId)) !== undefined) {
        directMessagesCache.insert(queryClient, message.ConversationId, message)
      }

      if (message.Sender?.Id && message.Sender.Id !== userIdRef.current && !conversationOpen && !mutedRef.current) {
        const senderName =
          message.Sender.Username ||
          [message.Sender.Name, message.Sender.Surname].filter(Boolean).join(' ') ||
          'Someone'
        const description = message.Content || 'Sent an attachment'
        const handleClick = () => navigateTo(`/dm/${message.ConversationId}`)

        toast({
          variant: 'info',
          title: senderName,
          description,
          avatarSrc: message.Sender.AvatarUrl ?? undefined,
          avatarName: senderName,
          onClick: handleClick,
          dedupeKey: `DirectMessageReceived:${message.Id}`,
        })
        showDesktopNotification({ title: senderName, body: description, icon: message.Sender.AvatarUrl, onClick: handleClick })
      }
    })

    const unsubscribeEdited = hub.onDirectMessageEdited((message) => {
      if (queryClient.getQueryData(directMessagesKeys.list(message.ConversationId)) !== undefined) {
        directMessagesCache.update(queryClient, message.ConversationId, message)
      }
    })

    const unsubscribeDeleted = hub.onDirectMessageDeleted(({ conversationId, messageId }) => {
      if (queryClient.getQueryData(directMessagesKeys.list(conversationId)) !== undefined) {
        directMessagesCache.remove(queryClient, conversationId, messageId)
      }
    })

    const unsubscribeReactions = hub.onDirectMessageReactionsChanged((message) => {
      if (queryClient.getQueryData(directMessagesKeys.list(message.ConversationId)) !== undefined) {
        directMessagesCache.update(queryClient, message.ConversationId, message)
      }
    })

    const unsubscribePinned = hub.onDirectMessagePinned((message) => {
      if (queryClient.getQueryData(directMessagesKeys.list(message.ConversationId)) !== undefined) {
        directMessagesCache.update(queryClient, message.ConversationId, message)
      }
    })

    const unsubscribeUnpinned = hub.onDirectMessageUnpinned((message) => {
      if (queryClient.getQueryData(directMessagesKeys.list(message.ConversationId)) !== undefined) {
        directMessagesCache.update(queryClient, message.ConversationId, message)
      }
    })

    const unsubscribeTyping = hub.onUserTyping((event) => {
      if (!event?.conversationId || !event?.userId) return
      const key = `${event.conversationId}:${event.userId}`

      setTypingByConversation((current) => {
        const existing = current[event.conversationId]
        if (existing?.has(event.userId)) return current
        const next = new Set(existing)
        next.add(event.userId)
        return { ...current, [event.conversationId]: next }
      })

      clearTimeout(timeouts.get(key))
      timeouts.set(
        key,
        setTimeout(() => {
          timeouts.delete(key)
          setTypingByConversation((current) => {
            const existing = current[event.conversationId]
            if (!existing?.has(event.userId)) return current
            const next = new Set(existing)
            next.delete(event.userId)
            if (next.size === 0) {
              const rest = { ...current }
              delete rest[event.conversationId]
              return rest
            }
            return { ...current, [event.conversationId]: next }
          })
        }, TYPING_EXPIRY_MS),
      )
    })

    const unsubscribeStoppedTyping = hub.onUserStoppedTyping((event) => {
      if (!event?.conversationId || !event?.userId) return
      const key = `${event.conversationId}:${event.userId}`
      clearTimeout(timeouts.get(key))
      timeouts.delete(key)

      setTypingByConversation((current) => {
        const existing = current[event.conversationId]
        if (!existing?.has(event.userId)) return current
        const next = new Set(existing)
        next.delete(event.userId)
        if (next.size === 0) {
          const rest = { ...current }
          delete rest[event.conversationId]
          return rest
        }
        return { ...current, [event.conversationId]: next }
      })
    })

    const unsubscribeConversationRead = hub.onConversationRead((event) => {
      if (!event?.conversationId || !event?.readAt) return
      setReadReceiptsByConversation((current) => ({ ...current, [event.conversationId]: event.readAt }))
    })

    hub.start().catch((error) => {
      console.error('Failed to connect to the direct messages hub', error)
      toast({
        variant: 'danger',
        title: 'Live updates disconnected',
        description: "You may not see new direct messages until you refresh.",
      })
    })

    return () => {
      hubRef.current = null
      unsubscribeReceived()
      unsubscribeEdited()
      unsubscribeDeleted()
      unsubscribeReactions()
      unsubscribePinned()
      unsubscribeUnpinned()
      unsubscribeTyping()
      unsubscribeStoppedTyping()
      unsubscribeConversationRead()
      for (const timeout of timeouts.values()) clearTimeout(timeout)
      timeouts.clear()
      setTypingByConversation({})
      setReadReceiptsByConversation({})
      hub.stop().catch(() => {})
    }
  }, [isAuthenticated, queryClient])

  const notifyTyping = useCallback((conversationId) => {
    if (!conversationId) return
    hubRef.current?.notifyTyping(conversationId).catch(() => {})
  }, [])

  const stopTyping = useCallback((conversationId) => {
    if (!conversationId) return
    hubRef.current?.stopTyping(conversationId).catch(() => {})
  }, [])

  return (
    <DirectMessagesContext.Provider
      value={{ typingByConversation, notifyTyping, stopTyping, readReceiptsByConversation }}
    >
      {children}
    </DirectMessagesContext.Provider>
  )
}
