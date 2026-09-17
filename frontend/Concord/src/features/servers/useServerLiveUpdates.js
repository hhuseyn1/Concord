import { useQueryClient } from '@tanstack/react-query'
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { createServersHub } from '../../api/hubs/serversHub'
import { toast } from '../../components/ui/Toast'
import { channelsKeys } from '../channels/channelsQueries'
import { rolesKeys } from '../roles/rolesQueries'
import { serversKeys } from './serversQueries'

export function useServerLiveUpdates(serverId) {
  const queryClient = useQueryClient()
  const navigate = useNavigate()

  useEffect(() => {
    if (!serverId) return undefined

    const hub = createServersHub()
    let stopped = false

    const invalidateChannels = () => queryClient.invalidateQueries({ queryKey: channelsKeys.list(serverId) })
    const invalidateMembers = () => queryClient.invalidateQueries({ queryKey: serversKeys.members(serverId) })

    const unsubscribeChannelCreated = hub.onChannelCreated((channel) => {
      if (channel?.ServerId !== serverId) return
      invalidateChannels()
    })
    const unsubscribeChannelUpdated = hub.onChannelUpdated((channel) => {
      if (channel?.ServerId !== serverId) return
      invalidateChannels()
    })
    const unsubscribeChannelDeleted = hub.onChannelDeleted((event) => {
      if (event?.serverId !== serverId) return
      invalidateChannels()
    })
    const unsubscribeMemberJoined = hub.onServerMemberJoined((event) => {
      if (event?.serverId !== serverId) return
      invalidateMembers()
    })
    const unsubscribeMemberLeft = hub.onServerMemberLeft((event) => {
      if (event?.serverId !== serverId) return
      invalidateMembers()
    })
    const unsubscribeUpdated = hub.onServerUpdated((server) => {
      if (!server?.Id) return
      queryClient.setQueryData(serversKeys.list(), (servers) =>
        servers ? servers.map((existing) => (existing.Id === server.Id ? server : existing)) : servers,
      )
    })

    const unsubscribeModeration = hub.onServerModerationChanged((event) => {
      if (event?.serverId !== serverId) return
      invalidateMembers()
      queryClient.invalidateQueries({ queryKey: rolesKeys.mine(serverId) })
    })

    const unsubscribeRemoved = hub.onRemovedFromServer((event) => {
      if (event?.serverId !== serverId) return
      queryClient.invalidateQueries({ queryKey: serversKeys.list() })
      toast({ variant: 'info', title: 'Removed from server', description: "You're no longer a member of this server." })
      navigate('/cabinet')
    })

    hub.connection.onreconnected(() => {
      hub.joinServer(serverId).catch((error) => console.error('Failed to rejoin server group', error))
    })

    hub
      .start()
      .then(() => {
        if (stopped) return undefined
        return hub.joinServer(serverId)
      })
      .catch((error) => {
        console.error('Failed to connect to the servers hub', error)
        toast({
          variant: 'danger',
          title: 'Live updates disconnected',
          description: "You may not see new channels or members here until you refresh.",
        })
      })

    return () => {
      stopped = true
      unsubscribeChannelCreated()
      unsubscribeChannelUpdated()
      unsubscribeChannelDeleted()
      unsubscribeMemberJoined()
      unsubscribeMemberLeft()
      unsubscribeUpdated()
      unsubscribeModeration()
      unsubscribeRemoved()
      hub.leaveServer(serverId).catch(() => {})
      hub.stop().catch(() => {})
    }
  }, [queryClient, serverId, navigate])
}
