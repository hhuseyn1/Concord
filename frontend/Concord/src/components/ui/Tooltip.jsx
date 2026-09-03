import * as RadixTooltip from '@radix-ui/react-tooltip'
import { cn } from '../../lib/cn'

export function Tooltip({ content, children, side = 'top', delayDuration = 200, className }) {
  return (
    <RadixTooltip.Provider delayDuration={delayDuration}>
      <RadixTooltip.Root>
        <RadixTooltip.Trigger asChild>{children}</RadixTooltip.Trigger>
        <RadixTooltip.Portal>
          <RadixTooltip.Content
            side={side}
            sideOffset={6}
            className={cn(
              'z-50 max-w-xs rounded-md border border-border-default bg-surface-floating px-2.5 py-1.5 text-xs text-fg-default shadow-md',
              'motion-safe:data-[state=delayed-open]:animate-content-in motion-safe:data-[state=instant-open]:animate-content-in motion-safe:data-[state=closed]:animate-content-out',
              className,
            )}
          >
            {content}
            <RadixTooltip.Arrow className="fill-surface-floating" />
          </RadixTooltip.Content>
        </RadixTooltip.Portal>
      </RadixTooltip.Root>
    </RadixTooltip.Provider>
  )
}
