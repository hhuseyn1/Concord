import { HubConnectionState } from '@microsoft/signalr'
import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { createMessagesHub } from '../../api/hubs/messagesHub'
import { toast } from '../../components/ui/Toast'
import { messagesCache } from './messagesQueries'

const TYPING_EXPIRY_MS = 6000

export function useMessagesLiveUpdates(serverId, channelId) {
  const queryClient = useQueryClient()
  const hubRef = useRef(null)
  const channelIdRef = useRef(channelId)
  const typingTimeoutsRef = useRef(new Map())
  const [typingUserIds, setTypingUserIds] = useState(() => new Set())

  useEffect(() => {
    channelIdRef.current = channelId
  }, [channelId])

  useEffect(() => {
    if (!serverId) return undefined

    const hub = createMessagesHub()
    hubRef.current = hub
    let stopped = false
    const timeouts = typingTimeoutsRef.current

    const unsubscribeReceived = hub.onMessageReceived((message) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId) return
      insertIfForThisChannel(queryClient, serverId, currentChannelId, message)
    })
    const unsubscribeEdited = hub.onMessageEdited((message) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId || (message?.ChannelId && message.ChannelId !== currentChannelId)) return
      messagesCache.update(queryClient, serverId, currentChannelId, message)
    })
    const unsubscribeDeleted = hub.onMessageDeleted((messageId) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId) return
      messagesCache.remove(queryClient, serverId, currentChannelId, messageId)
    })
    const unsubscribeReactions = hub.onMessageReactionsChanged((message) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId || (message?.ChannelId && message.ChannelId !== currentChannelId)) return
      messagesCache.update(queryClient, serverId, currentChannelId, message)
    })
    const unsubscribePinned = hub.onMessagePinned((message) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId || (message?.ChannelId && message.ChannelId !== currentChannelId)) return
      messagesCache.update(queryClient, serverId, currentChannelId, message)
    })
    const unsubscribeUnpinned = hub.onMessageUnpinned((message) => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId || (message?.ChannelId && message.ChannelId !== currentChannelId)) return
      messagesCache.update(queryClient, serverId, currentChannelId, message)
    })
    const unsubscribeTyping = hub.onUserTyping((event) => {
      if (!event?.userId || event.channelId !== channelIdRef.current) return

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
      if (!event?.userId || event.channelId !== channelIdRef.current) return
      clearTimeout(timeouts.get(event.userId))
      timeouts.delete(event.userId)
      setTypingUserIds((current) => {
        if (!current.has(event.userId)) return current
        const next = new Set(current)
        next.delete(event.userId)
        return next
      })
    })

    const joinCurrentChannel = () => {
      const currentChannelId = channelIdRef.current
      if (!currentChannelId) return Promise.resolve()
      return hub.joinChannel(currentChannelId).catch((error) => {
        console.error('Failed to join channel group', error)
      })
    }
    hub.connection.onreconnected(() => joinCurrentChannel())

    hub
      .start()
      .then(() => {
        if (stopped) return undefined
        return joinCurrentChannel()
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
      hub.stop().catch(() => {})
    }
  }, [queryClient, serverId])

  const [prevChannelId, setPrevChannelId] = useState(channelId)
  if (channelId !== prevChannelId) {
    setPrevChannelId(channelId)
    setTypingUserIds(new Set())
  }

  useEffect(() => {
    if (!channelId) return undefined
    const hub = hubRef.current

    const timeouts = typingTimeoutsRef.current
    for (const timeout of timeouts.values()) clearTimeout(timeout)
    timeouts.clear()

    if (!hub || hub.connection.state !== HubConnectionState.Connected) {
      return undefined
    }

    hub.joinChannel(channelId).catch((error) => console.error('Failed to join channel group', error))

    return () => {
      hub.stopTyping(channelId).catch(() => {})
      hub.leaveChannel(channelId).catch(() => {})
    }
  }, [channelId])

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
