import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { createMessagesHub } from '../../api/hubs/messagesHub'
import { toast } from '../../components/ui/Toast'
import { messagesCache } from './messagesQueries'

const TYPING_EXPIRY_MS = 6000

export function useMessagesLiveUpdates(serverId, channelId) {
  const queryClient = useQueryClient()
  const hubRef = useRef(null)
  const typingTimeoutsRef = useRef(new Map())
  const [typingUserIds, setTypingUserIds] = useState(() => new Set())

  useEffect(() => {
    if (!serverId || !channelId) return undefined

    const hub = createMessagesHub()
    hubRef.current = hub
    let stopped = false
    const timeouts = typingTimeoutsRef.current

    const unsubscribeReceived = hub.onMessageReceived((message) => {
      insertIfForThisChannel(queryClient, serverId, channelId, message)
    })
    const unsubscribeEdited = hub.onMessageEdited((message) => {
      if (message?.ChannelId && message.ChannelId !== channelId) return
      messagesCache.update(queryClient, serverId, channelId, message)
    })
    const unsubscribeDeleted = hub.onMessageDeleted((messageId) => {
      messagesCache.remove(queryClient, serverId, channelId, messageId)
    })
    const unsubscribeReactions = hub.onMessageReactionsChanged((message) => {
      if (message?.ChannelId && message.ChannelId !== channelId) return
      messagesCache.update(queryClient, serverId, channelId, message)
    })
    const unsubscribePinned = hub.onMessagePinned((message) => {
      if (message?.ChannelId && message.ChannelId !== channelId) return
      messagesCache.update(queryClient, serverId, channelId, message)
    })
    const unsubscribeUnpinned = hub.onMessageUnpinned((message) => {
      if (message?.ChannelId && message.ChannelId !== channelId) return
      messagesCache.update(queryClient, serverId, channelId, message)
    })
    const unsubscribeTyping = hub.onUserTyping((event) => {
      if (!event?.userId || event.channelId !== channelId) return

      setTypingUserIds((current) => (current.has(event.userId) ? current : new Set(current).add(event.userId)))

      clearTimeout(timeouts.get(event.userId))
      timeouts.set(
        event.userId,
        setTimeout(() => {
          timeouts.delete(event.userId)
          setTypingUserIds((current) => {
            if (!current.has(event.userId)) return current
            const next = new Set(current)
            next.delete(event.userId)
            return next
          })
        }, TYPING_EXPIRY_MS),
      )
    })
    const unsubscribeStoppedTyping = hub.onUserStoppedTyping((event) => {
      if (!event?.userId || event.channelId !== channelId) return
      clearTimeout(timeouts.get(event.userId))
      timeouts.delete(event.userId)
      setTypingUserIds((current) => {
        if (!current.has(event.userId)) return current
        const next = new Set(current)
        next.delete(event.userId)
        return next
      })
    })

    hub
      .start()
      .then(() => {
        if (stopped) return undefined
        return hub.joinChannel(channelId)
      })
      .catch((error) => {
        console.error('Failed to connect to the messages hub', error)
        toast({
          variant: 'danger',
          title: 'Live updates disconnected',
          description: "You may not see new messages here until you refresh.",
        })
      })

    return () => {
      stopped = true
      hubRef.current = null
      unsubscribeReceived()
      unsubscribeEdited()
      unsubscribeDeleted()
      unsubscribeReactions()
      unsubscribePinned()
      unsubscribeUnpinned()
      unsubscribeTyping()
      unsubscribeStoppedTyping()
      for (const timeout of timeouts.values()) clearTimeout(timeout)
      timeouts.clear()
      setTypingUserIds(new Set())
      hub.stopTyping(channelId).catch(() => {})
      hub.leaveChannel(channelId).catch(() => {})
      hub.stop().catch(() => {})
    }
  }, [queryClient, serverId, channelId])

  const notifyTyping = useCallback(() => {
    if (!channelId) return
    hubRef.current?.notifyTyping(channelId).catch(() => {})
  }, [channelId])

  const stopTyping = useCallback(() => {
    if (!channelId) return
    hubRef.current?.stopTyping(channelId).catch(() => {})
  }, [channelId])

  return { typingUserIds, notifyTyping, stopTyping }
}

function insertIfForThisChannel(queryClient, serverId, channelId, message) {
  if (message?.ChannelId && message.ChannelId !== channelId) return
  messagesCache.insert(queryClient, serverId, channelId, message)
}
