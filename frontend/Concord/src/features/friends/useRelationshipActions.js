import { useState } from 'react'
import { toast } from '../../components/ui/Toast'
import { mapBlockError, mapRequestActionError, mapSendFriendRequestError, mapUnblockError } from './friendsErrors'
import {
  useAcceptFriendRequestMutation,
  useBlockUserMutation,
  useCancelFriendRequestMutation,
  useDeclineFriendRequestMutation,
  useSendFriendRequestMutation,
  useUnblockUserMutation,
} from './friendsQueries'

export function useRelationshipActions({ onChanged } = {}) {
  const [pendingIds, setPendingIds] = useState(() => new Set())
  const sendMutation = useSendFriendRequestMutation()
  const acceptMutation = useAcceptFriendRequestMutation()
  const declineMutation = useDeclineFriendRequestMutation()
  const cancelMutation = useCancelFriendRequestMutation()
  const blockMutation = useBlockUserMutation()
  const unblockMutation = useUnblockUserMutation()

  const withPending = (userId, fn) => async () => {
    setPendingIds((current) => new Set(current).add(userId))
    try {
      await fn()
      onChanged?.()
    } finally {
      setPendingIds((current) => {
        const next = new Set(current)
        next.delete(userId)
        return next
      })
    }
  }

  const displayName = (user) => user?.Username || [user?.Name, user?.Surname].filter(Boolean).join(' ') || 'this user'

  const sendRequest = (user) =>
    withPending(user.Id, async () => {
      try {
        const result = await sendMutation.mutateAsync(user.Id)
        toast({
          variant: 'success',
          title: result.Status === 'Accepted' ? 'Friend request accepted' : 'Friend request sent',
          description:
            result.Status === 'Accepted'
              ? `${displayName(user)} had already sent you a request, so you're friends now.`
              : `Sent a friend request to ${displayName(user)}.`,
        })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not send request', description: mapSendFriendRequestError(error) })
      }
    })()

  const acceptRequest = (user) =>
    withPending(user.Id, async () => {
      try {
        await acceptMutation.mutateAsync(user.PendingRequestId)
        toast({ variant: 'success', title: 'Friend request accepted', description: `You and ${displayName(user)} are now friends.` })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not accept request', description: mapRequestActionError(error) })
      }
    })()

  const declineRequest = (user) =>
    withPending(user.Id, async () => {
      try {
        await declineMutation.mutateAsync(user.PendingRequestId)
        toast({ description: 'Friend request declined.' })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not decline request', description: mapRequestActionError(error) })
      }
    })()

  const cancelRequest = (user) =>
    withPending(user.Id, async () => {
      try {
        await cancelMutation.mutateAsync(user.PendingRequestId)
        toast({ description: 'Friend request canceled.' })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not cancel request', description: mapRequestActionError(error) })
      }
    })()

  const blockUser = (user) =>
    withPending(user.Id, async () => {
      try {
        await blockMutation.mutateAsync(user.Id)
        toast({ variant: 'success', title: 'User blocked', description: `${displayName(user)} was blocked.` })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not block user', description: mapBlockError(error) })
      }
    })()

  const unblockUser = (user) =>
    withPending(user.Id, async () => {
      try {
        await unblockMutation.mutateAsync(user.Id)
        toast({ variant: 'success', title: 'User unblocked', description: `${displayName(user)} can interact with you again.` })
      } catch (error) {
        toast({ variant: 'danger', title: 'Could not unblock user', description: mapUnblockError(error) })
      }
    })()

  return {
    isPending: (userId) => pendingIds.has(userId),
    sendRequest,
    acceptRequest,
    declineRequest,
    cancelRequest,
    blockUser,
    unblockUser,
  }
}
