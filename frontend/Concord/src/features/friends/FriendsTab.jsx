import { MessageSquare, UserX, Users } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { IconButton } from '../../components/ui/IconButton'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { Tooltip } from '../../components/ui/Tooltip'
import * as directMessagesService from '../../api/directMessagesService'
import { mapCreateConversationError } from '../directMessages/directMessagesErrors'
import { mapBlockError } from './friendsErrors'
import { FriendRow } from './FriendRow'
import { useBlockUserMutation, useFriendsList } from './friendsQueries'
import { presenceSortWeight } from './presence'

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1">
      {Array.from({ length: 5 }, (_, index) => (
        <div key={index} className="flex items-center gap-3 px-3 py-2">
          <Skeleton className="size-10 rounded-full" />
          <Skeleton className="h-4 w-32" />
        </div>
      ))}
    </div>
  )
}

export function FriendsTab() {
  const navigate = useNavigate()
  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage, refetch } =
    useFriendsList()
  const blockMutation = useBlockUserMutation()
  const [startingDmFor, setStartingDmFor] = useState(null)
  const [blockTarget, setBlockTarget] = useState(null)

  const friends = useMemo(() => {
    const items = data?.pages.flatMap((page) => page.Items) ?? []
    return [...items].sort((a, b) => presenceSortWeight(a.Status) - presenceSortWeight(b.Status))
  }, [data])

  const totalCount = data?.pages?.[0]?.TotalCount ?? friends.length

  const handleMessage = async (user) => {
    setStartingDmFor(user.Id)
    try {
      const conversation = await directMessagesService.createOrGetConversation(user.Id)
      navigate(`/dm/${conversation.Id}`)
    } catch (dmError) {
      toast({ variant: 'danger', title: 'Could not start conversation', description: mapCreateConversationError(dmError) })
    } finally {
      setStartingDmFor(null)
    }
  }

  const handleConfirmBlock = async () => {
    if (!blockTarget) return
    const user = blockTarget
    setBlockTarget(null)
    try {
      await blockMutation.mutateAsync(user.Id)
      toast({
        variant: 'success',
        title: 'User blocked',
        description: `${user.Username || 'This user'} was blocked and removed from your friends.`,
      })
    } catch (blockError) {
      toast({ variant: 'danger', title: 'Could not block user', description: mapBlockError(blockError) })
    }
  }

  if (isLoading) {
    return <RowSkeletons />
  }

  if (isError) {
    return (
      <EmptyState
        title="Couldn't load friends"
        description={error?.message || 'Something went wrong.'}
        action={
          <Button variant="secondary" size="sm" onClick={() => refetch()}>
            Try again
          </Button>
        }
      />
    )
  }

  if (friends.length === 0) {
    return (
      <EmptyState
        icon={Users}
        title="No friends yet"
        description="Search for someone in the Add Friend tab to send a request."
      />
    )
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="px-3 text-xs font-semibold tracking-wide text-fg-muted uppercase">
        All friends — {totalCount}
      </p>
      <div className="flex flex-col gap-0.5">
        {friends.map((user) => (
          <FriendRow
            key={user.Id}
            user={user}
            actions={
              <>
                <Tooltip content="Message">
                  <IconButton
                    aria-label={`Message ${user.Username || 'this user'}`}
                    variant="ghost"
                    size="sm"
                    disabled={startingDmFor === user.Id}
                    onClick={() => handleMessage(user)}
                  >
                    {startingDmFor === user.Id ? <Spinner size="sm" /> : <MessageSquare className="size-4" aria-hidden="true" />}
                  </IconButton>
                </Tooltip>
                <Tooltip content="Block">
                  <IconButton
                    aria-label={`Block ${user.Username || 'this user'}`}
                    variant="ghost"
                    size="sm"
                    disabled={blockMutation.isPending}
                    onClick={() => setBlockTarget(user)}
                  >
                    <UserX className="size-4" aria-hidden="true" />
                  </IconButton>
                </Tooltip>
              </>
            }
          />
        ))}
      </div>
      {hasNextPage && (
        <div className="flex justify-center pt-2">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => fetchNextPage()}
            disabled={isFetchingNextPage}
          >
            {isFetchingNextPage ? 'Loading…' : 'Load more'}
          </Button>
        </div>
      )}

      <Modal
        open={Boolean(blockTarget)}
        onOpenChange={(open) => !open && setBlockTarget(null)}
        title="Block this user?"
        description={`${blockTarget?.Username || 'This user'} will be removed from your friends and won't be able to message you or see your profile. There's no separate "unfriend" — this is the only way to end the friendship.`}
        footer={
          <>
            <Button variant="ghost" onClick={() => setBlockTarget(null)}>
              Cancel
            </Button>
            <Button variant="danger" onClick={handleConfirmBlock} disabled={blockMutation.isPending}>
              Block User
            </Button>
          </>
        }
      />
    </div>
  )
}
