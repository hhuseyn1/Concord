import { MessageSquare } from 'lucide-react'
import { useState } from 'react'
import { Navigate, useParams } from 'react-router-dom'
import { Button } from '../components/ui/Button'
import { EmptyState } from '../components/ui/EmptyState'
import { Spinner } from '../components/ui/Spinner'
import { CreateChannelModal } from '../features/channels/CreateChannelModal'
import { useChannels } from '../features/channels/channelsQueries'
import { useServers } from '../features/servers/serversQueries'
import { useAuth } from '../hooks/useAuth'

function CenteredPlaceholder({ children }) {
  return <div className="flex flex-1 items-center justify-center p-8">{children}</div>
}

export function ServerPlaceholder() {
  const { serverId } = useParams()
  const { user } = useAuth()
  const { data: servers } = useServers()
  const server = servers?.find((item) => item.Id === serverId)
  const isOwner = Boolean(server && user && server.OwnerId === user.Id)
  const { data: channels, isLoading: channelsLoading } = useChannels(serverId)
  const [createOpen, setCreateOpen] = useState(false)

  if (channels && channels.length > 0) {
    const target = channels.find((channel) => channel.Type === 'Text') ?? channels[0]
    return <Navigate to={`/cabinet/servers/${serverId}/channels/${target.Id}`} replace />
  }

  return (
    <CenteredPlaceholder>
      {channelsLoading ? (
        <Spinner />
      ) : (
        <EmptyState
          icon={MessageSquare}
          title="No channels yet"
          description={
            isOwner
              ? `Create the first channel in "${server?.Name ?? 'this server'}" to get started.`
              : `"${server?.Name ?? 'This server'}" doesn't have any channels yet.`
          }
          action={
            isOwner && (
              <Button onClick={() => setCreateOpen(true)}>Create Channel</Button>
            )
          }
        />
      )}
      {isOwner && (
        <CreateChannelModal serverId={serverId} open={createOpen} onOpenChange={setCreateOpen} />
      )}
    </CenteredPlaceholder>
  )
}

export function NotFoundPlaceholder() {
  return (
    <CenteredPlaceholder>
      <EmptyState title="Page not found" description="That route doesn't exist." />
    </CenteredPlaceholder>
  )
}
