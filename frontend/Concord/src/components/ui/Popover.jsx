import * as RadixPopover from '@radix-ui/react-popover'
import { cn } from '../../lib/cn'

export const Popover = RadixPopover.Root
export const PopoverTrigger = RadixPopover.Trigger
export const PopoverAnchor = RadixPopover.Anchor
export const PopoverClose = RadixPopover.Close

export function PopoverContent({
  className,
  align = 'center',
  side = 'bottom',
  sideOffset = 8,
  children,
  ...props
}) {
  return (
    <RadixPopover.Portal>
      <RadixPopover.Content
        align={align}
        side={side}
        sideOffset={sideOffset}
        className={cn(
          'z-50 w-72 rounded-lg border border-border-default bg-surface-floating p-4 text-sm text-fg-default shadow-lg outline-none',
          'motion-safe:data-[state=open]:animate-content-in motion-safe:data-[state=closed]:animate-content-out',
          className,
        )}
        {...props}
      >
        {children}
        <RadixPopover.Arrow className="fill-surface-floating" />
      </RadixPopover.Content>
    </RadixPopover.Portal>
  )
}
