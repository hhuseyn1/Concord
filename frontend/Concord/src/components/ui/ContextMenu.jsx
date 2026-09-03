import * as RadixContextMenu from '@radix-ui/react-context-menu'
import { Check, ChevronRight, Circle } from 'lucide-react'
import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

export const ContextMenu = RadixContextMenu.Root
export const ContextMenuTrigger = RadixContextMenu.Trigger
export const ContextMenuGroup = RadixContextMenu.Group
export const ContextMenuSub = RadixContextMenu.Sub
export const ContextMenuRadioGroup = RadixContextMenu.RadioGroup

const contentClasses =
  'z-50 min-w-[10rem] rounded-md border border-border-default bg-surface-floating p-1 text-sm text-fg-default shadow-md ' +
  'motion-safe:data-[state=open]:animate-content-in motion-safe:data-[state=closed]:animate-content-out'

export const ContextMenuContent = forwardRef(function ContextMenuContent(
  { className, ...props },
  ref,
) {
  return (
    <RadixContextMenu.Portal>
      <RadixContextMenu.Content ref={ref} className={cn(contentClasses, className)} {...props} />
    </RadixContextMenu.Portal>
  )
})

export const ContextMenuSubContent = forwardRef(function ContextMenuSubContent(
  { className, ...props },
  ref,
) {
  return (
    <RadixContextMenu.Portal>
      <RadixContextMenu.SubContent ref={ref} className={cn(contentClasses, className)} {...props} />
    </RadixContextMenu.Portal>
  )
})

const itemClasses =
  'relative flex cursor-pointer select-none items-center gap-2 rounded-sm px-2 py-1.5 outline-none ' +
  'data-[highlighted]:bg-brand-bg data-[highlighted]:text-fg-default ' +
  'data-[disabled]:pointer-events-none data-[disabled]:opacity-50'

export const ContextMenuItem = forwardRef(function ContextMenuItem(
  { className, danger = false, ...props },
  ref,
) {
  return (
    <RadixContextMenu.Item
      ref={ref}
      className={cn(itemClasses, danger && 'text-danger data-[highlighted]:bg-danger-bg', className)}
      {...props}
    />
  )
})

export const ContextMenuSubTrigger = forwardRef(function ContextMenuSubTrigger(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixContextMenu.SubTrigger ref={ref} className={cn(itemClasses, className)} {...props}>
      {children}
      <ChevronRight className="ml-auto size-3.5" aria-hidden="true" />
    </RadixContextMenu.SubTrigger>
  )
})

export const ContextMenuCheckboxItem = forwardRef(function ContextMenuCheckboxItem(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixContextMenu.CheckboxItem ref={ref} className={cn(itemClasses, 'pl-7', className)} {...props}>
      <span className="absolute left-2 flex size-3.5 items-center justify-center">
        <RadixContextMenu.ItemIndicator>
          <Check className="size-3.5" aria-hidden="true" />
        </RadixContextMenu.ItemIndicator>
      </span>
      {children}
    </RadixContextMenu.CheckboxItem>
  )
})

export const ContextMenuRadioItem = forwardRef(function ContextMenuRadioItem(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixContextMenu.RadioItem ref={ref} className={cn(itemClasses, 'pl-7', className)} {...props}>
      <span className="absolute left-2 flex size-3.5 items-center justify-center">
        <RadixContextMenu.ItemIndicator>
          <Circle className="size-2 fill-current" aria-hidden="true" />
        </RadixContextMenu.ItemIndicator>
      </span>
      {children}
    </RadixContextMenu.RadioItem>
  )
})

export const ContextMenuLabel = forwardRef(function ContextMenuLabel({ className, ...props }, ref) {
  return (
    <RadixContextMenu.Label
      ref={ref}
      className={cn('px-2 py-1.5 text-xs font-semibold text-fg-muted', className)}
      {...props}
    />
  )
})

export const ContextMenuSeparator = forwardRef(function ContextMenuSeparator(
  { className, ...props },
  ref,
) {
  return (
    <RadixContextMenu.Separator ref={ref} className={cn('my-1 h-px bg-border-default', className)} {...props} />
  )
})
