import { ShieldOff } from 'lucide-react'
import { useMemo } from 'react'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { mapUnblockError } from './friendsErrors'
import { FriendRow } from './FriendRow'
import { useBlockedUsersList, useUnblockUserMutation } from './friendsQueries'

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1">
      {Array.from({ length: 3 }, (_, index) => (
        <div key={index} className="flex items-center gap-3 px-3 py-2">
          <Skeleton className="size-10 rounded-full" />
          <Skeleton className="h-4 w-32" />
        </div>
      ))}
    </div>
  )
}

export function BlockedTab() {
  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage, refetch } =
    useBlockedUsersList()
  const unblockMutation = useUnblockUserMutation()

  const blocked = useMemo(() => data?.pages.flatMap((page) => page.Items) ?? [], [data])
  const totalCount = data?.pages?.[0]?.TotalCount ?? blocked.length

  const handleUnblock = async (user) => {
    try {
      await unblockMutation.mutateAsync(user.Id)
      toast({
        variant: 'success',
        title: 'User unblocked',
        description: `${user.Username || 'This user'} can interact with you again.`,
      })
    } catch (unblockError) {
      toast({ variant: 'danger', title: 'Could not unblock user', description: mapUnblockError(unblockError) })
    }
  }

  if (isLoading) {
    return <RowSkeletons />
  }

  if (isError) {
    return (
      <EmptyState
        title="Couldn't load blocked users"
        description={error?.message || 'Something went wrong.'}
        action={
          <Button variant="secondary" size="sm" onClick={() => refetch()}>
            Try again
          </Button>
        }
      />
    )
  }

  if (blocked.length === 0) {
    return (
      <EmptyState
        icon={ShieldOff}
        title="No blocked users"
        description="Users you block will show up here. Blocking removes them from your friends and pending requests, and they can't message or friend-request you again unless you unblock them."
      />
    )
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="px-3 text-xs font-semibold tracking-wide text-fg-muted uppercase">
        Blocked - {totalCount}
      </p>
      <div className="flex flex-col gap-0.5">
        {blocked.map((user) => (
          <FriendRow
            key={user.Id}
            user={user}
            showPresence={false}
            actions={
              <Button
                size="sm"
                variant="secondary"
                disabled={unblockMutation.isPending}
                onClick={() => handleUnblock(user)}
              >
                Unblock
              </Button>
            }
          />
        ))}
      </div>
      {hasNextPage && (
        <div className="flex justify-center pt-2">
          <Button variant="secondary" size="sm" onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
            {isFetchingNextPage ? 'Loading…' : 'Load more'}
          </Button>
        </div>
      )}
    </div>
  )
}
