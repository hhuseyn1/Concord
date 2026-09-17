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
        // A plain string, never the `({ isActive }) => ...` function form NavLink also accepts:
        // this element is the direct child of Tooltip's Radix `asChild` trigger, whose Slot clones
        // this element and merges its own className into ours via a plain string join *before*
        // NavLink ever gets to call that function itself. Handed a function instead of a string,
        // that join silently stringifies it (`Function.prototype.toString`), so the DOM's actual
        // class ends up being the function's literal source text - most of it garbage, but a few
        // bare words in there happen to match real utilities (`ring-2`, `ring-brand`,
        // `ring-offset-2`) and so apply unconditionally, while `ring-offset-surface-rail` and
        // `rounded-2xl` get mangled by adjacent quotes/parens and never match anything. Net effect:
        // every icon - active or not - got a ring with no ring-offset-color override, so it fell
        // back to Tailwind's default (white), then got clipped by the rail's overflow into stray
        // top/left slivers. The active-state look now lives entirely on Avatar below instead, via
        // the children render-prop, which isn't subject to this Slot merge at all.
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
