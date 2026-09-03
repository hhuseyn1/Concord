import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { createPresenceHub } from '../api/hubs/presenceHub'
import { friendsKeys } from '../features/friends/friendsQueries'
import { serversKeys } from '../features/servers/serversQueries'
import { useIdleDetection } from '../hooks/useIdleDetection'
import { useAuth } from '../hooks/useAuth'
import { PresenceContext } from './PresenceContext'

const IDLE_TIMEOUT_MS = 5 * 60 * 1000

export function PresenceProvider({ children }) {
  const { isAuthenticated, user } = useAuth()
  const queryClient = useQueryClient()
  const [status, setStatusState] = useState('Online')
  const hubRef = useRef(null)
  const statusRef = useRef('Online')
  const autoIdleRef = useRef(false)
  const hydratedRef = useRef(false)

  useEffect(() => {
    if (!isAuthenticated) {
      hydratedRef.current = false
      return
    }
    if (hydratedRef.current || !user?.Status) return
    hydratedRef.current = true
    statusRef.current = user.Status
    setStatusState(user.Status)
  }, [isAuthenticated, user?.Status])

  useEffect(() => {
    if (!isAuthenticated) return undefined

    const hub = createPresenceHub()
    hubRef.current = hub

    const unsubscribe = hub.onPresenceChanged((change) => {
      if (!change?.userId) return
      patchFriendsCache(queryClient, change)
      patchServerMembersCache(queryClient, change)
    })

    hub.start().catch((error) => {
      console.error('Failed to connect to the presence hub', error)
    })

    return () => {
      unsubscribe()
      hubRef.current = null
      hub.stop().catch(() => {})
    }
  }, [isAuthenticated, queryClient])

  const setStatus = useCallback(async (nextStatus, { auto = false } = {}) => {
    autoIdleRef.current = auto
    statusRef.current = nextStatus
    setStatusState(nextStatus)
    try {
      await hubRef.current?.setStatus(nextStatus)
    } catch (error) {
      console.error('Failed to update presence status', error)
    }
  }, [])

  useIdleDetection({
    enabled: isAuthenticated,
    idleTimeoutMs: IDLE_TIMEOUT_MS,
    onIdle: () => {
      if (statusRef.current === 'Online') setStatus('Idle', { auto: true })
    },
    onActive: () => {
      if (autoIdleRef.current && statusRef.current === 'Idle') setStatus('Online', { auto: false })
    },
  })

  return <PresenceContext.Provider value={{ status, setStatus }}>{children}</PresenceContext.Provider>
}

function patchFriendsCache(queryClient, change) {
  queryClient.setQueryData(friendsKeys.list(), (data) => {
    if (!data) return data
    return {
      ...data,
      pages: data.pages.map((page) => ({
        ...page,
        Items: page.Items.map((item) =>
          item.Id === change.userId ? { ...item, Status: change.status, LastSeenAt: change.lastSeenAt } : item,
        ),
      })),
    }
  })
}

function patchServerMembersCache(queryClient, change) {
  queryClient.setQueriesData(
    { queryKey: serversKeys.all, predicate: (query) => query.queryKey[2] === 'members' },
    (data) => {
      if (!data) return data
      return {
        ...data,
        pages: data.pages.map((page) => ({
          ...page,
          Items: page.Items.map((item) =>
            item.User?.Id === change.userId
              ? { ...item, User: { ...item.User, Status: change.status, LastSeenAt: change.lastSeenAt } }
              : item,
          ),
        })),
      }
    },
  )
}
