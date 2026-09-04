import { Clock, MicOff, Users } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { Tooltip } from '../../components/ui/Tooltip'
import { useAuth } from '../../hooks/useAuth'
import { cn } from '../../lib/cn'
import { toAvatarPresence } from '../friends/presence'
import { MemberModerationMenu } from '../moderation/MemberModerationMenu'
import { useCan } from '../roles/rolesQueries'
import { mapRemoveMemberError } from '../servers/serversErrors'
import {
  flattenServerMemberPages,
  useRemoveMemberMutation,
  useServerMembers,
  useServers,
} from '../servers/serversQueries'
import { ProfilePopover } from './ProfilePopover'

const GROUPS = [
  { key: 'Online', label: 'Online' },
  { key: 'Idle', label: 'Idle' },
  { key: 'Offline', label: 'Offline' },
]

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1 p-2">
      {Array.from({ length: 6 }, (_, index) => (
        <div key={index} className="flex items-center gap-3 px-2 py-1.5">
          <Skeleton className="size-8 rounded-full" />
          <Skeleton className="h-3.5 w-24" />
        </div>
      ))}
    </div>
  )
}

export function MemberListPanel() {
  const { t } = useTranslation()
  const { serverId } = useParams()
  const { user } = useAuth()
  const { data: servers } = useServers()
  const server = serverId ? servers?.find((item) => item.Id === serverId) : undefined
  const { can } = useCan(serverId)
  const canKick = can('KickMembers')
  const [removeTarget, setRemoveTarget] = useState(null)
  const removeMemberMutation = useRemoveMemberMutation(serverId)

  const {
    data,
    isLoading,
    isError,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    refetch,
  } = useServerMembers(serverId, { enabled: Boolean(serverId) })

  const members = useMemo(() => flattenServerMemberPages(data?.pages), [data])
  const totalCount = data?.pages?.[0]?.TotalCount ?? members.length

  const handleConfirmRemove = async () => {
    if (!removeTarget) return
    try {
      await removeMemberMutation.mutateAsync(removeTarget.User.Id)
      setRemoveTarget(null)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not remove member', description: mapRemoveMemberError(error) })
      setRemoveTarget(null)
    }
  }

  const grouped = useMemo(() => {
    const buckets = { Online: [], Idle: [], Offline: [] }
    for (const member of members) {
      const bucket = buckets[member.User?.Status] ?? buckets.Offline
      bucket.push(member)
    }
    return buckets
  }, [members])

  if (!serverId) {
    return (
      <div className="p-4">
        <EmptyState
          icon={Users}
          title="No server selected"
          description="Select a server to see its member list."
        />
      </div>
    )
  }

  if (isLoading) {
    return (
      <ScrollArea className="min-h-0 flex-1">
        <RowSkeletons />
      </ScrollArea>
    )
  }

  if (isError) {
    return (
      <div className="p-4">
        <EmptyState
          title="Couldn't load members"
          description={error?.message || 'Something went wrong.'}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              Try again
            </Button>
          }
        />
      </div>
    )
  }

  if (members.length === 0) {
    return (
      <div className="p-4">
        <EmptyState icon={Users} title="No members" description="This server has no members yet." />
      </div>
    )
  }

  return (
    <>
      <ScrollArea className="min-h-0 flex-1">
      <div className="flex flex-col gap-4 p-2 py-3">
        {GROUPS.map(({ key, label }) => {
          const items = grouped[key]
          if (items.length === 0) return null
          return (
            <div key={key} className="flex flex-col gap-0.5">
              <p className="px-2 pb-1 text-xs font-semibold tracking-wide text-fg-muted uppercase">
                {label} - {items.length}
              </p>
              {items.map((member) => {
                const canRemove = canKick && member.User?.Id && member.User.Id !== user?.Id && member.User.Id !== server?.OwnerId
                const displayName =
                  member.User?.Username ||
                  [member.User?.Name, member.User?.Surname].filter(Boolean).join(' ') ||
                  'Unknown user'
                const isTimedOut = Boolean(member.TimedOutUntil) && new Date(member.TimedOutUntil) > new Date()
                return (
                  <div key={member.User?.Id} className="group relative">
                    <ProfilePopover userId={member.User?.Id} side="left" align="start">
                      <button
                        type="button"
                        className={cn(
                          'flex w-full items-center gap-3 rounded-md px-2 py-1.5 text-left transition-colors duration-150 hover:bg-fg-default/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
                          'pr-9',
                        )}
                      >
                        <Avatar
                          src={member.User?.AvatarUrl ?? undefined}
                          name={displayName}
                          presence={toAvatarPresence(member.User?.Status)}
                          size="sm"
                        />
                        <span className="truncate text-sm font-medium text-fg-default">{displayName}</span>
                        {member.IsMuted && (
                          <Tooltip content={t('moderation.mutedBadge')}>
                            <MicOff className="size-3.5 shrink-0 text-fg-muted" aria-label={t('moderation.mutedBadge')} />
                          </Tooltip>
                        )}
                        {isTimedOut && (
                          <Tooltip content={t('moderation.timedOutBadge', { date: new Date(member.TimedOutUntil).toLocaleString() })}>
                            <Clock className="size-3.5 shrink-0 text-fg-muted" aria-label={t('moderation.timedOutUntilLabel')} />
                          </Tooltip>
                        )}
                      </button>
                    </ProfilePopover>
                    <div className="absolute top-1/2 right-1 hidden -translate-y-1/2 group-hover:flex">
                      <MemberModerationMenu
                        serverId={serverId}
                        member={member}
                        isSelf={member.User?.Id === user?.Id}
                        isTargetOwner={member.User?.Id === server?.OwnerId}
                        canKick={canRemove}
                        onKick={() => setRemoveTarget(member)}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          )
        })}

        {hasNextPage && (
          <div className="flex justify-center">
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

        <p className="px-2 text-xs text-fg-muted">
          {totalCount} member{totalCount === 1 ? '' : 's'}
        </p>
      </div>
      </ScrollArea>

      <Modal
        open={Boolean(removeTarget)}
        onOpenChange={(open) => !open && setRemoveTarget(null)}
        title="Remove this member?"
        description={`${removeTarget?.User?.Username || [removeTarget?.User?.Name, removeTarget?.User?.Surname].filter(Boolean).join(' ') || 'This member'} will be removed from the server immediately. They can rejoin later with a new invite.`}
        footer={
          <>
            <Button variant="ghost" onClick={() => setRemoveTarget(null)}>
              Cancel
            </Button>
            <Button variant="danger" onClick={handleConfirmRemove} disabled={removeMemberMutation.isPending}>
              Remove Member
            </Button>
          </>
        }
      />
    </>
  )
}
