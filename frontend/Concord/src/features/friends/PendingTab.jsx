import { Inbox, Send } from 'lucide-react'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { mapRequestActionError } from './friendsErrors'
import { FriendRow } from './FriendRow'
import {
  useAcceptFriendRequestMutation,
  useCancelFriendRequestMutation,
  useDeclineFriendRequestMutation,
  useIncomingRequests,
  useOutgoingRequests,
} from './friendsQueries'

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1">
      {Array.from({ length: 2 }, (_, index) => (
        <div key={index} className="flex items-center gap-3 px-3 py-2">
          <Skeleton className="size-10 rounded-full" />
          <Skeleton className="h-4 w-32" />
        </div>
      ))}
    </div>
  )
}

function SectionHeading({ icon: Icon, children }) {
  return (
    <p className="flex items-center gap-1.5 px-3 text-xs font-semibold tracking-wide text-fg-muted uppercase">
      <Icon className="size-3.5" aria-hidden="true" />
      {children}
    </p>
  )
}

function IncomingSection() {
  const { data, isLoading, isError, error, refetch } = useIncomingRequests()
  const acceptMutation = useAcceptFriendRequestMutation()
  const declineMutation = useDeclineFriendRequestMutation()
  const busy = acceptMutation.isPending || declineMutation.isPending

  const handleAccept = async (request) => {
    try {
      await acceptMutation.mutateAsync(request.Id)
      toast({
        variant: 'success',
        title: 'Friend request accepted',
        description: `You and ${request.User?.Username || 'this user'} are now friends.`,
      })
    } catch (actionError) {
      toast({
        variant: 'danger',
        title: 'Could not accept request',
        description: mapRequestActionError(actionError),
      })
    }
  }

  const handleDecline = async (request) => {
    try {
      await declineMutation.mutateAsync(request.Id)
      toast({ description: 'Friend request declined.' })
    } catch (actionError) {
      toast({
        variant: 'danger',
        title: 'Could not decline request',
        description: mapRequestActionError(actionError),
      })
    }
  }

  return (
    <section className="flex flex-col gap-2">
      <SectionHeading icon={Inbox}>Incoming{data ? ` — ${data.length}` : ''}</SectionHeading>
      {isLoading ? (
        <RowSkeletons />
      ) : isError ? (
        <EmptyState
          title="Couldn't load incoming requests"
          description={error?.message || 'Something went wrong.'}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              Try again
            </Button>
          }
        />
      ) : data.length === 0 ? (
        <EmptyState compact title="No incoming requests." />
      ) : (
        <div className="flex flex-col gap-0.5">
          {data.map((request) => (
            <FriendRow
              key={request.Id}
              user={request.User}
              actions={
                <>
                  <Button size="sm" disabled={busy} onClick={() => handleAccept(request)}>
                    Accept
                  </Button>
                  <Button
                    size="sm"
                    variant="secondary"
                    disabled={busy}
                    onClick={() => handleDecline(request)}
                  >
                    Decline
                  </Button>
                </>
              }
            />
          ))}
        </div>
      )}
    </section>
  )
}

function OutgoingSection() {
  const { data, isLoading, isError, error, refetch } = useOutgoingRequests()
  const cancelMutation = useCancelFriendRequestMutation()

  const handleCancel = async (request) => {
    try {
      await cancelMutation.mutateAsync(request.Id)
      toast({ description: 'Friend request canceled.' })
    } catch (actionError) {
      toast({
        variant: 'danger',
        title: 'Could not cancel request',
        description: mapRequestActionError(actionError),
      })
    }
  }

  return (
    <section className="flex flex-col gap-2">
      <SectionHeading icon={Send}>Outgoing{data ? ` — ${data.length}` : ''}</SectionHeading>
      {isLoading ? (
        <RowSkeletons />
      ) : isError ? (
        <EmptyState
          title="Couldn't load outgoing requests"
          description={error?.message || 'Something went wrong.'}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              Try again
            </Button>
          }
        />
      ) : data.length === 0 ? (
        <EmptyState compact title="No outgoing requests." />
      ) : (
        <div className="flex flex-col gap-0.5">
          {data.map((request) => (
            <FriendRow
              key={request.Id}
              user={request.User}
              subtitle="Pending"
              actions={
                <Button
                  size="sm"
                  variant="secondary"
                  disabled={cancelMutation.isPending}
                  onClick={() => handleCancel(request)}
                >
                  Cancel
                </Button>
              }
            />
          ))}
        </div>
      )}
    </section>
  )
}

export function PendingTab() {
  return (
    <div className="flex flex-col gap-6">
      <IncomingSection />
      <OutgoingSection />
    </div>
  )
}
