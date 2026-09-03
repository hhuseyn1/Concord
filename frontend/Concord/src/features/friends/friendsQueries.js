import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as friendsService from '../../api/friendsService'

const FRIENDS_PAGE_SIZE = 30

export const friendsKeys = {
  all: ['friends'],
  list: () => [...friendsKeys.all, 'list'],
  incoming: () => [...friendsKeys.all, 'requests', 'incoming'],
  outgoing: () => [...friendsKeys.all, 'requests', 'outgoing'],
  blocked: () => [...friendsKeys.all, 'blocked'],
}

export function useFriendsList() {
  return useInfiniteQuery({
    queryKey: friendsKeys.list(),
    queryFn: ({ pageParam }) => friendsService.getFriends({ page: pageParam, pageSize: FRIENDS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
  })
}

export function useIncomingRequests() {
  return useQuery({
    queryKey: friendsKeys.incoming(),
    queryFn: friendsService.getIncomingFriendRequests,
  })
}

export function useOutgoingRequests() {
  return useQuery({
    queryKey: friendsKeys.outgoing(),
    queryFn: friendsService.getOutgoingFriendRequests,
  })
}

export function useSendFriendRequestMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (targetUserId) => friendsService.sendFriendRequest(targetUserId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: friendsKeys.outgoing() })
      queryClient.invalidateQueries({ queryKey: friendsKeys.list() })
    },
  })
}

export function useAcceptFriendRequestMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (requestId) => friendsService.acceptFriendRequest(requestId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: friendsKeys.incoming() })
      queryClient.invalidateQueries({ queryKey: friendsKeys.list() })
    },
  })
}

export function useDeclineFriendRequestMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (requestId) => friendsService.declineFriendRequest(requestId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: friendsKeys.incoming() }),
  })
}

export function useCancelFriendRequestMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (requestId) => friendsService.cancelFriendRequest(requestId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: friendsKeys.outgoing() }),
  })
}

export function useBlockUserMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (targetUserId) => friendsService.blockUser(targetUserId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: friendsKeys.all }),
  })
}

export function useUnblockUserMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (targetUserId) => friendsService.unblockUser(targetUserId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: friendsKeys.all }),
  })
}

export function useBlockedUsersList() {
  return useInfiniteQuery({
    queryKey: friendsKeys.blocked(),
    queryFn: ({ pageParam }) => friendsService.getBlockedUsers({ page: pageParam, pageSize: FRIENDS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
  })
}
