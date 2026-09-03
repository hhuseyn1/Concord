import { Crown, Users } from 'lucide-react'
import { Avatar } from '../../components/ui/Avatar'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { useAuth } from '../../hooks/useAuth'
import { ServerHeaderMenu } from '../servers/ServerHeaderMenu'
import { useServers } from '../servers/serversQueries'

export function ServersSettingsTab() {
  const { user } = useAuth()
  const { data: servers, isLoading, isError } = useServers()

  if (isLoading) {
    return (
      <div className="flex max-w-md flex-col gap-2">
        {Array.from({ length: 3 }, (_, index) => (
          <div
            key={index}
            className="flex items-center gap-3 rounded-md border border-border-default px-3 py-2"
          >
            <Skeleton className="size-10 rounded-full" />
            <Skeleton className="h-4 w-32" />
          </div>
        ))}
      </div>
    )
  }

  if (isError) {
    return <EmptyState title="Couldn't load your servers" description="Try again in a moment." />
  }

  if (!servers || servers.length === 0) {
    return (
      <EmptyState
        icon={Users}
        title="No servers yet"
        description="Join or create a server from the server rail to see it here."
      />
    )
  }

  return (
    <div className="flex max-w-md flex-col gap-2">
      {servers.map((server) => {
        const isOwner = Boolean(user && server.OwnerId === user.Id)
        return (
          <div
            key={server.Id}
            className="flex items-center gap-3 rounded-md border border-border-default bg-surface-sidebar px-3 py-2"
          >
            <Avatar src={server.IconUrl ?? undefined} name={server.Name || 'Server'} size="md" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-fg-default">{server.Name || 'Server'}</p>
              <p className="flex items-center gap-1 text-xs text-fg-muted">
                {isOwner && <Crown className="size-3" aria-hidden="true" />}
                {isOwner ? 'Owner' : 'Member'}
              </p>
            </div>
            <ServerHeaderMenu server={server} isOwner={isOwner} />
          </div>
        )
      })}
    </div>
  )
}
