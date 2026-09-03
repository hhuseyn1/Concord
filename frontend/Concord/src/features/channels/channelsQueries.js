import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as channelsService from '../../api/channelsService'

export const channelsKeys = {
  all: ['channels'],
  list: (serverId) => [...channelsKeys.all, serverId],
}

export function useChannels(serverId, { enabled = true } = {}) {
  return useQuery({
    queryKey: channelsKeys.list(serverId),
    queryFn: () => channelsService.getChannels(serverId),
    enabled: enabled && Boolean(serverId),
  })
}

export function useCreateChannelMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => channelsService.createChannel(serverId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: channelsKeys.list(serverId) }),
  })
}

export function useUpdateChannelMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ channelId, name }) => channelsService.updateChannel(serverId, channelId, name),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: channelsKeys.list(serverId) }),
  })
}

export function useDeleteChannelMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (channelId) => channelsService.deleteChannel(serverId, channelId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: channelsKeys.list(serverId) }),
  })
}
