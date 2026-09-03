import { Hash, Pencil, Trash2, Volume2 } from 'lucide-react'
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { Badge } from '../../components/ui/Badge'
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuTrigger,
} from '../../components/ui/ContextMenu'
import { cn } from '../../lib/cn'
import { DeleteChannelModal } from './DeleteChannelModal'
import { RenameChannelModal } from './RenameChannelModal'

export function ChannelRow({ channel, serverId, canManageChannels }) {
  const [renameOpen, setRenameOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const Icon = channel.Type === 'Voice' ? Volume2 : Hash
  const hasUnread = channel.UnreadCount > 0

  const row = (
    <NavLink
      to={`/servers/${serverId}/channels/${channel.Id}`}
      className={({ isActive }) =>
        cn(
          'flex items-center gap-2 rounded-md px-2 py-1.5 text-sm font-medium text-fg-muted motion-safe:animate-row-in',
          'transition-colors duration-150 hover:bg-fg-default/10 hover:text-fg-default',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
          isActive && 'bg-fg-default/10 text-fg-default',
          hasUnread && 'text-fg-default',
        )
      }
    >
      <Icon className="size-4 shrink-0" aria-hidden="true" />
      <span className={cn('min-w-0 flex-1 truncate', hasUnread && 'font-semibold')}>{channel.Name}</span>
      {hasUnread && (
        <Badge variant="danger" className="shrink-0">
          {channel.UnreadCount > 99 ? '99+' : channel.UnreadCount}
        </Badge>
      )}
    </NavLink>
  )

  if (!canManageChannels) {
    return row
  }

  return (
    <>
      <ContextMenu>
        <ContextMenuTrigger asChild>{row}</ContextMenuTrigger>
        <ContextMenuContent>
          <ContextMenuItem onSelect={() => setRenameOpen(true)}>
            <Pencil className="size-4" aria-hidden="true" />
            Rename Channel
          </ContextMenuItem>
          <ContextMenuItem danger onSelect={() => setDeleteOpen(true)}>
            <Trash2 className="size-4" aria-hidden="true" />
            Delete Channel
          </ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>

      <RenameChannelModal channel={channel} serverId={serverId} open={renameOpen} onOpenChange={setRenameOpen} />
      <DeleteChannelModal channel={channel} serverId={serverId} open={deleteOpen} onOpenChange={setDeleteOpen} />
    </>
  )
}
