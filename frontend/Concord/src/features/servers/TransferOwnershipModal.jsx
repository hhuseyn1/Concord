import { Search, UserCog } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { cn } from '../../lib/cn'
import { mapTransferOwnershipError } from './serversErrors'
import { flattenServerMemberPages, useServerMembers, useTransferOwnershipMutation } from './serversQueries'

export function TransferOwnershipModal({ server, open, onOpenChange }) {
  const { user } = useAuth()
  const [query, setQuery] = useState('')
  const [selectedId, setSelectedId] = useState(null)
  const { data, isLoading, isError, hasNextPage, isFetchingNextPage, fetchNextPage } = useServerMembers(
    server?.Id,
    { enabled: open },
  )
  const transferMutation = useTransferOwnershipMutation(server?.Id)

  const members = useMemo(() => flattenServerMemberPages(data?.pages), [data])
  const totalCount = data?.pages?.[0]?.TotalCount ?? members.length

  const candidates = useMemo(() => {
    const withoutSelf = members.filter((member) => member.User?.Id !== user?.Id)
    const needle = query.trim().toLowerCase()
    if (!needle) return withoutSelf
    return withoutSelf.filter((member) => {
      const name = member.User?.Username || [member.User?.Name, member.User?.Surname].filter(Boolean).join(' ')
      return (name || '').toLowerCase().includes(needle)
    })
  }, [members, user?.Id, query])

  const handleClose = (next) => {
    onOpenChange(next)
    if (!next) {
      setSelectedId(null)
      setQuery('')
    }
  }

  const handleTransfer = async () => {
    if (!selectedId) return
    try {
      await transferMutation.mutateAsync(selectedId)
      toast({
        variant: 'success',
        title: 'Ownership transferred',
        description: "You're no longer the owner of this server.",
      })
      handleClose(false)
    } catch (error) {
      toast({
        variant: 'danger',
        title: 'Could not transfer ownership',
        description: mapTransferOwnershipError(error),
      })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={handleClose}
      title={`Transfer ownership of ${server?.Name || 'this server'}`}
      description="Pick another member to become the new owner. You'll remain a member, and will then be able to leave the server yourself if you want to."
      footer={
        <>
          <Button variant="ghost" onClick={() => handleClose(false)}>
            Cancel
          </Button>
          <Button variant="danger" disabled={!selectedId || transferMutation.isPending} onClick={handleTransfer}>
            {transferMutation.isPending && <Spinner size="sm" />}
            Transfer ownership
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-3">
        <div className="relative">
          <Search
            className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-fg-muted"
            aria-hidden="true"
          />
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Filter members by username…"
            className="pl-9"
            aria-label="Filter members by username"
          />
        </div>

        {isLoading ? (
          <div className="flex flex-col gap-1">
            {Array.from({ length: 3 }, (_, index) => (
              <div key={index} className="flex items-center gap-3 px-2 py-1.5">
                <Skeleton className="size-8 rounded-full" />
                <Skeleton className="h-4 w-24" />
              </div>
            ))}
          </div>
        ) : isError ? (
          <EmptyState title="Couldn't load members" description="Try again in a moment." />
        ) : candidates.length === 0 ? (
          <EmptyState
            icon={UserCog}
            title="No other members"
            description="There's nobody else in this server to transfer ownership to yet."
          />
        ) : (
          <div className="flex max-h-64 flex-col gap-0.5 overflow-y-auto">
            {candidates.map((member) => {
              const isSelected = selectedId === member.User?.Id
              const displayName =
                member.User?.Username ||
                [member.User?.Name, member.User?.Surname].filter(Boolean).join(' ') ||
                'Unknown user'
              return (
                <button
                  key={member.User?.Id}
                  type="button"
                  onClick={() => setSelectedId(member.User?.Id)}
                  className={cn(
                    'flex items-center gap-3 rounded-md px-2 py-1.5 text-left transition-colors duration-150',
                    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
                    isSelected ? 'bg-brand-bg' : 'hover:bg-fg-default/5',
                  )}
                >
                  <Avatar src={member.User?.AvatarUrl ?? undefined} name={displayName} size="sm" />
                  <span className="truncate text-sm text-fg-default">{displayName}</span>
                </button>
              )
            })}
          </div>
        )}

        {data && (
          <div className="flex items-center justify-between gap-2">
            <p className="text-xs text-fg-muted">
              Showing {members.length} of {totalCount} members.
            </p>
            {hasNextPage && (
              <Button
                variant="secondary"
                size="sm"
                onClick={() => fetchNextPage()}
                disabled={isFetchingNextPage}
              >
                {isFetchingNextPage ? 'Loading…' : 'Load more'}
              </Button>
            )}
          </div>
        )}
      </div>
    </Modal>
  )
}
