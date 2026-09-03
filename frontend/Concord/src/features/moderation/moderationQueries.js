import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import * as moderationService from '../../api/moderationService'
import { rolesKeys } from '../roles/rolesQueries'
import { serversKeys } from '../servers/serversQueries'

const BANS_PAGE_SIZE = 30

export const moderationKeys = {
  all: ['moderation'],
  bans: (serverId) => [...moderationKeys.all, serverId, 'bans'],
  member: (serverId, userId) => [...moderationKeys.all, serverId, 'member', userId],
}

export function flattenBanPages(data) {
  return data?.pages?.flatMap((page) => page.Items ?? []) ?? []
}

export function useBans(serverId, enabled = true) {
  return useInfiniteQuery({
    queryKey: moderationKeys.bans(serverId),
    queryFn: ({ pageParam = 1 }) => moderationService.getBans(serverId, pageParam, BANS_PAGE_SIZE),
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
    initialPageParam: 1,
    enabled: Boolean(serverId) && enabled,
  })
}

function invalidateModeration(queryClient, serverId, userId) {
  queryClient.invalidateQueries({ queryKey: serversKeys.members(serverId) })
  queryClient.invalidateQueries({ queryKey: moderationKeys.member(serverId, userId) })
  queryClient.invalidateQueries({ queryKey: rolesKeys.mine(serverId) })
}

export function useBanMemberMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, ...data }) => moderationService.banMember(serverId, userId, data),
    onSuccess: (_result, { userId }) => {
      queryClient.invalidateQueries({ queryKey: moderationKeys.bans(serverId) })
      invalidateModeration(queryClient, serverId, userId)
    },
  })
}

export function useUnbanUserMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (userId) => moderationService.unbanUser(serverId, userId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: moderationKeys.bans(serverId) }),
  })
}

export function useSetMuteMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, muted }) =>
      muted ? moderationService.muteMember(serverId, userId) : moderationService.unmuteMember(serverId, userId),
    onSuccess: (_result, { userId }) => invalidateModeration(queryClient, serverId, userId),
  })
}

export function useTimeoutMemberMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, ...data }) => moderationService.timeoutMember(serverId, userId, data),
    onSuccess: (_result, { userId }) => invalidateModeration(queryClient, serverId, userId),
  })
}

export function useRemoveTimeoutMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (userId) => moderationService.removeTimeout(serverId, userId),
    onSuccess: (_result, userId) => invalidateModeration(queryClient, serverId, userId),
  })
}
