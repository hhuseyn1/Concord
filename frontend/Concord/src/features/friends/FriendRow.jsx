import { Avatar } from '../../components/ui/Avatar'
import { toAvatarPresence } from './presence'

export function FriendRow({ user, actions, subtitle, showPresence = true }) {
  const displayName =
    user?.Username || [user?.Name, user?.Surname].filter(Boolean).join(' ') || 'Unknown user'

  return (
    <div className="flex items-center gap-3 rounded-md px-3 py-2 transition-colors duration-150 hover:bg-fg-default/5">
      <Avatar
        src={user?.AvatarUrl ?? undefined}
        name={displayName}
        presence={showPresence ? toAvatarPresence(user?.Status) : undefined}
        size="md"
      />
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium text-fg-default">{displayName}</p>
        {subtitle && <p className="truncate text-xs text-fg-muted">{subtitle}</p>}
      </div>
      {actions && <div className="flex shrink-0 items-center gap-1.5">{actions}</div>}
    </div>
  )
}
