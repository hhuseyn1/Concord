import { NavLink } from 'react-router-dom'
import { Avatar } from '../../components/ui/Avatar'
import { Tooltip } from '../../components/ui/Tooltip'
import { cn } from '../../lib/cn'

export function ServerIcon({ server }) {
  return (
    <Tooltip content={server.Name || 'Server'} side="right">
      <NavLink
        to={`/cabinet/servers/${server.Id}`}
        aria-label={server.Name || 'Server'}
        className="flex size-12 shrink-0 items-center justify-center rounded-full transition-[border-radius] duration-150 [transition-timing-function:var(--ease-standard)] hover:rounded-2xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-rail"
      >
        {({ isActive }) => (
          <Avatar
            src={server.IconUrl ?? undefined}
            name={server.Name || 'Server'}
            size="lg"
            shape={isActive ? 'squircle' : 'circle'}
            className={cn(
              'pointer-events-none size-full',
              isActive && 'ring-2 ring-brand ring-offset-2 ring-offset-surface-rail',
            )}
          />
        )}
      </NavLink>
    </Tooltip>
  )
}
