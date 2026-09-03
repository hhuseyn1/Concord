import { Plus, Users } from 'lucide-react'
import { useState } from 'react'
import { NavLink, useParams } from 'react-router-dom'
import { ChannelRow } from '../../features/channels/ChannelRow'
import { CreateChannelModal } from '../../features/channels/CreateChannelModal'
import { mapGetChannelsError } from '../../features/channels/channelsErrors'
import { useChannels } from '../../features/channels/channelsQueries'
import { mapGetConversationsError } from '../../features/directMessages/directMessagesErrors'
import { flattenConversationPages, useConversations } from '../../features/directMessages/directMessagesQueries'
import { toAvatarPresence } from '../../features/friends/presence'
import { useCan } from '../../features/roles/rolesQueries'
import { ServerHeaderMenu } from '../../features/servers/ServerHeaderMenu'
import { useServers } from '../../features/servers/serversQueries'
import { useAuth } from '../../hooks/useAuth'
import { cn } from '../../lib/cn'
import { Avatar } from '../ui/Avatar'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { EmptyState } from '../ui/EmptyState'
import { IconButton } from '../ui/IconButton'
import { ScrollArea } from '../ui/ScrollArea'
import { Skeleton } from '../ui/Skeleton'
import { Tooltip } from '../ui/Tooltip'
import { UserPanel } from './UserPanel'

function FriendsNav() {
  return (
    <nav className="flex flex-col gap-0.5 p-2" aria-label="Friends navigation">
      <NavLink
        to="/"
        end
        className={({ isActive }) =>
          cn(
            'flex items-center gap-2 rounded-md px-2 py-1.5 text-sm font-medium text-fg-muted',
            'transition-colors duration-150 hover:bg-fg-default/10 hover:text-fg-default',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
            isActive && 'bg-fg-default/10 text-fg-default',
          )
        }
      >
        <Users className="size-4" aria-hidden="true" />
        Friends
      </NavLink>
    </nav>
  )
}

function ConversationsNav() {
  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage } = useConversations()
  const conversations = flattenConversationPages(data?.pages)

  return (
    <nav className="flex flex-col gap-0.5 px-2 pt-2" aria-label="Direct messages">
      <p className="px-2 pt-1 pb-1 text-xs font-semibold tracking-wide text-fg-muted uppercase">
        Direct Messages
      </p>
      {isLoading ? (
        <div className="flex flex-col gap-2 px-2 py-1">
          {Array.from({ length: 3 }, (_, index) => (
            <Skeleton key={index} className="h-8 w-full" />
          ))}
        </div>
      ) : isError ? (
        <p className="px-2 py-1 text-sm text-fg-muted">{mapGetConversationsError(error)}</p>
      ) : conversations.length === 0 ? (
        <EmptyState compact title="No conversations yet." />
      ) : (
        conversations.map((conversation) => {
          const displayName =
            conversation.OtherUser?.Username ||
            [conversation.OtherUser?.Name, conversation.OtherUser?.Surname].filter(Boolean).join(' ') ||
            'Unknown user'

          return (
            <NavLink
              key={conversation.Id}
              to={`/dm/${conversation.Id}`}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-2 rounded-md px-2 py-1.5 text-sm text-fg-muted motion-safe:animate-row-in',
                  'transition-colors duration-150 hover:bg-fg-default/10 hover:text-fg-default',
                  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
                  isActive && 'bg-fg-default/10 text-fg-default',
                )
              }
            >
              <Avatar
                src={conversation.OtherUser?.AvatarUrl ?? undefined}
                name={displayName}
                presence={toAvatarPresence(conversation.OtherUser?.Status)}
                size="sm"
              />
              <span className="min-w-0 flex-1">
                <span className="block truncate font-medium text-fg-default">{displayName}</span>
                {conversation.LastMessage && (
                  <span className="block truncate text-xs text-fg-muted">
                    {conversation.LastMessage.Content}
                  </span>
                )}
              </span>
              {conversation.UnreadCount > 0 && (
                <Badge variant="danger" className="shrink-0">
                  {conversation.UnreadCount > 99 ? '99+' : conversation.UnreadCount}
                </Badge>
              )}
            </NavLink>
          )
        })
      )}
      {hasNextPage && (
        <div className="flex justify-center pt-1 pb-1">
          <Button variant="secondary" size="sm" onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
            {isFetchingNextPage ? 'Loading…' : 'Load more'}
          </Button>
        </div>
      )}
    </nav>
  )
}

function ChannelGroup({ label, type, channels, serverId, canManageChannels, onCreateChannel }) {
  const groupChannels = channels.filter((channel) => channel.Type === type)

  return (
    <div className="flex flex-col gap-0.5 px-2">
      <div className="flex items-center justify-between pt-3 pb-1 pl-2">
        <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">{label}</p>
        {canManageChannels && (
          <Tooltip content={`Create ${label.toLowerCase()} channel`}>
            <IconButton
              aria-label={`Create ${label.toLowerCase()} channel`}
              variant="ghost"
              size="sm"
              onClick={() => onCreateChannel(type)}
            >
              <Plus className="size-4" aria-hidden="true" />
            </IconButton>
          </Tooltip>
        )}
      </div>
      {groupChannels.length === 0 ? (
        <EmptyState compact title={`No ${label.toLowerCase()} channels yet.`} />
      ) : (
        groupChannels.map((channel) => (
          <ChannelRow key={channel.Id} channel={channel} serverId={serverId} canManageChannels={canManageChannels} />
        ))
      )}
    </div>
  )
}

export function ChannelSidebar({ className }) {
  const { serverId } = useParams()
  const { user } = useAuth()
  const { data: servers, isLoading: serversLoading } = useServers()
  const server = serverId ? servers?.find((item) => item.Id === serverId) : undefined
  const isOwner = Boolean(server && user && server.OwnerId === user.Id)
  const { can } = useCan(serverId)
  const canManageChannels = can('ManageChannels')
  const {
    data: channels,
    isLoading: channelsLoading,
    isError: channelsError,
    error: channelsErrorDetail,
  } = useChannels(serverId)
  const [createType, setCreateType] = useState(null)

  return (
    <aside
      aria-label={serverId ? 'Channels' : 'Friends'}
      className={cn(
        'flex h-full w-60 shrink-0 flex-col border-r border-border-default bg-surface-sidebar',
        className,
      )}
    >
      <div className="flex h-12 shrink-0 items-center justify-between gap-2 border-b border-border-subtle px-3 shadow-sm">
        {!serverId ? (
          <p className="truncate px-1 text-sm font-semibold text-fg-heading">Concord</p>
        ) : server ? (
          <>
            <div className="flex min-w-0 flex-1 items-center gap-2 px-1">
              <Avatar src={server.IconUrl ?? undefined} name={server.Name} size="sm" />
              <p className="truncate text-sm font-semibold text-fg-heading">{server.Name}</p>
            </div>
            <ServerHeaderMenu server={server} isOwner={isOwner} />
          </>
        ) : serversLoading ? (
          <div className="flex flex-1 items-center gap-2 px-1">
            <Skeleton className="size-6 rounded-full" />
            <Skeleton className="h-4 w-24" />
          </div>
        ) : (
          <p className="truncate px-1 text-sm font-semibold text-fg-heading">Unknown server</p>
        )}
      </div>

      <ScrollArea className="min-h-0 flex-1">
        {serverId ? (
          channelsLoading ? (
            <div className="flex flex-col gap-2 p-2">
              {Array.from({ length: 4 }, (_, index) => (
                <Skeleton key={index} className="h-6 w-full" />
              ))}
            </div>
          ) : channelsError ? (
            <p className="p-3 text-sm text-fg-muted">{mapGetChannelsError(channelsErrorDetail)}</p>
          ) : (
            <div className="flex flex-col gap-2 py-2">
              <ChannelGroup
                label="Text"
                type="Text"
                channels={channels ?? []}
                serverId={serverId}
                canManageChannels={canManageChannels}
                onCreateChannel={setCreateType}
              />
              <ChannelGroup
                label="Voice"
                type="Voice"
                channels={channels ?? []}
                serverId={serverId}
                canManageChannels={canManageChannels}
                onCreateChannel={setCreateType}
              />
            </div>
          )
        ) : (
          <>
            <FriendsNav />
            <ConversationsNav />
          </>
        )}
      </ScrollArea>

      <UserPanel />

      {serverId && canManageChannels && (
        <CreateChannelModal
          serverId={serverId}
          open={Boolean(createType)}
          onOpenChange={(open) => setCreateType(open ? createType : null)}
          defaultType={createType ?? 'Text'}
        />
      )}
    </aside>
  )
}
