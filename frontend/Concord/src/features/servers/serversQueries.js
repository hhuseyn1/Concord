import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as serversService from '../../api/serversService'

const MEMBERS_PAGE_SIZE = 30

export const serversKeys = {
  all: ['servers'],
  list: () => [...serversKeys.all, 'list'],
  members: (serverId) => [...serversKeys.all, serverId, 'members'],
  invites: (serverId) => [...serversKeys.all, serverId, 'invites'],
}

export function useServers() {
  return useQuery({
    queryKey: serversKeys.list(),
    queryFn: serversService.getMyServers,
  })
}

export function useCreateServerMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: serversService.createServer,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.list() }),
  })
}

export function useJoinServerMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (inviteCode) => serversService.joinServer(inviteCode),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.list() }),
  })
}

export function useUpdateServerMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => serversService.updateServer(serverId, data),
    onSuccess: (server) => {
      queryClient.setQueryData(serversKeys.list(), (servers) =>
        servers ? servers.map((existing) => (existing.Id === server.Id ? server : existing)) : servers,
      )
    },
  })
}

export function useLeaveServerMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (serverId) => serversService.leaveServer(serverId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.list() }),
  })
}

export function useDeleteServerMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (serverId) => serversService.deleteServer(serverId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.list() }),
  })
}

export function useRemoveMemberMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (userId) => serversService.removeServerMember(serverId, userId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.members(serverId) }),
  })
}

export function useTransferOwnershipMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (newOwnerUserId) => serversService.transferServerOwnership(serverId, newOwnerUserId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: serversKeys.list() })
      queryClient.invalidateQueries({ queryKey: serversKeys.members(serverId) })
    },
  })
}

export function useServerMembers(serverId, { enabled = true } = {}) {
  return useInfiniteQuery({
    queryKey: serversKeys.members(serverId),
    queryFn: ({ pageParam }) =>
      serversService.getServerMembers(serverId, { page: pageParam, pageSize: MEMBERS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
    enabled: enabled && Boolean(serverId),
  })
}

export function flattenServerMemberPages(pages) {
  return pages?.flatMap((page) => page.Items) ?? []
}

export function useGenerateInviteMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => serversService.createServerInvite(serverId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: serversKeys.invites(serverId) }),
  })
}

export function useServerInvites(serverId, { enabled = true } = {}) {
  return useQuery({
    queryKey: serversKeys.invites(serverId),
    queryFn: () => serversService.listServerInvites(serverId),
    enabled: enabled && Boolean(serverId),
  })
}
