import { Plus } from 'lucide-react'
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { AddServerModal } from '../../features/servers/AddServerModal'
import { ServerIcon } from '../../features/servers/ServerIcon'
import { useServers } from '../../features/servers/serversQueries'
import { cn } from '../../lib/cn'
import { IconButton } from '../ui/IconButton'
import { Skeleton } from '../ui/Skeleton'
import { Tooltip } from '../ui/Tooltip'

export function ServerRail() {
  const [addServerOpen, setAddServerOpen] = useState(false)
  const { data: servers, isLoading } = useServers()

  return (
    <nav
      aria-label="Servers"
      className="flex h-full w-[72px] shrink-0 flex-col items-center gap-2 overflow-y-auto bg-surface-rail py-3"
    >
      <Tooltip content="Home" side="right">
        <NavLink
          to="/cabinet"
          end
          // A plain string, never the `({ isActive }) => ...` function form NavLink also accepts.
          // This is the direct child of Tooltip's Radix `asChild` trigger, whose Slot clones this
          // element and merges its own className into ours via a plain string join *before*
          // NavLink ever calls that function itself - handed a function instead of a string, that
          // join silently stringifies it, so the DOM's actual class became the function's literal
          // source text (see the identical fix + longer explanation on ServerIcon's NavLink). All
          // the isActive-dependent styling below now lives on the inner span instead, via the
          // children render-prop, which isn't subject to this Slot merge at all. focus-visible
          // stays here because it must target the element that's actually focusable.
          className="flex size-12 shrink-0 items-center justify-center rounded-2xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-rail"
        >
          {({ isActive }) => (
            <span
              className={cn(
                'flex size-full items-center justify-center rounded-2xl bg-surface-sidebar text-fg-default',
                'transition-[border-radius,background-color] duration-150 [transition-timing-function:var(--ease-standard)]',
                'hover:rounded-xl hover:bg-brand hover:text-fg-on-brand',
                isActive && 'rounded-xl bg-brand text-fg-on-brand',
              )}
            >
              {/* Self-contained badge asset (own rounded-square + brand-blue fill baked in), not the
                * plain icon mark - this tile's hover/active state fills its own background with
                * `bg-brand`, and the plain mark's blue is too close to that to read against it. */}
              <img src="/logo-app-icon.png" alt="" className="size-9 rounded-xl" aria-hidden="true" />
              <span className="sr-only">Home (Friends)</span>
            </span>
          )}
        </NavLink>
      </Tooltip>

      <div className="h-px w-8 shrink-0 rounded-full bg-border-default" />

      <div className="flex flex-1 flex-col items-center gap-2 overflow-y-auto">
        {isLoading
          ? Array.from({ length: 2 }, (_, index) => (
              <Skeleton key={index} className="size-12 shrink-0 rounded-full" />
            ))
          : servers?.map((server) => <ServerIcon key={server.Id} server={server} />)}
      </div>

      <Tooltip content="Add a server" side="right">
        <IconButton
          aria-label="Add or join a server"
          variant="secondary"
          size="lg"
          className="shrink-0 rounded-2xl hover:rounded-xl"
          onClick={() => setAddServerOpen(true)}
        >
          <Plus className="size-5" aria-hidden="true" />
        </IconButton>
      </Tooltip>

      <AddServerModal open={addServerOpen} onOpenChange={setAddServerOpen} />
    </nav>
  )
}
