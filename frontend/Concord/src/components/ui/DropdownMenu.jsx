import * as RadixDropdownMenu from '@radix-ui/react-dropdown-menu'
import { Check, ChevronRight, Circle } from 'lucide-react'
import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

export const DropdownMenu = RadixDropdownMenu.Root
export const DropdownMenuTrigger = RadixDropdownMenu.Trigger
export const DropdownMenuGroup = RadixDropdownMenu.Group
export const DropdownMenuSub = RadixDropdownMenu.Sub
export const DropdownMenuRadioGroup = RadixDropdownMenu.RadioGroup

const contentClasses =
  'z-50 min-w-[10rem] rounded-md border border-border-default bg-surface-floating p-1 text-sm text-fg-default shadow-md ' +
  'motion-safe:data-[state=open]:animate-content-in motion-safe:data-[state=closed]:animate-content-out'

export const DropdownMenuContent = forwardRef(function DropdownMenuContent(
  { className, sideOffset = 6, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.Portal>
      <RadixDropdownMenu.Content
        ref={ref}
        sideOffset={sideOffset}
        className={cn(contentClasses, className)}
        {...props}
      />
    </RadixDropdownMenu.Portal>
  )
})

export const DropdownMenuSubContent = forwardRef(function DropdownMenuSubContent(
  { className, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.Portal>
      <RadixDropdownMenu.SubContent ref={ref} className={cn(contentClasses, className)} {...props} />
    </RadixDropdownMenu.Portal>
  )
})

const itemClasses =
  'relative flex cursor-pointer select-none items-center gap-2 rounded-sm px-2 py-1.5 outline-none ' +
  'data-[highlighted]:bg-brand-bg data-[highlighted]:text-fg-default ' +
  'data-[disabled]:pointer-events-none data-[disabled]:opacity-50'

export const DropdownMenuItem = forwardRef(function DropdownMenuItem(
  { className, danger = false, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.Item
      ref={ref}
      className={cn(itemClasses, danger && 'text-danger data-[highlighted]:bg-danger-bg', className)}
      {...props}
    />
  )
})

export const DropdownMenuSubTrigger = forwardRef(function DropdownMenuSubTrigger(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.SubTrigger ref={ref} className={cn(itemClasses, className)} {...props}>
      {children}
      <ChevronRight className="ml-auto size-3.5" aria-hidden="true" />
    </RadixDropdownMenu.SubTrigger>
  )
})

export const DropdownMenuCheckboxItem = forwardRef(function DropdownMenuCheckboxItem(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.CheckboxItem
      ref={ref}
      className={cn(itemClasses, 'pl-7', className)}
      {...props}
    >
      <span className="absolute left-2 flex size-3.5 items-center justify-center">
        <RadixDropdownMenu.ItemIndicator>
          <Check className="size-3.5" aria-hidden="true" />
        </RadixDropdownMenu.ItemIndicator>
      </span>
      {children}
    </RadixDropdownMenu.CheckboxItem>
  )
})

export const DropdownMenuRadioItem = forwardRef(function DropdownMenuRadioItem(
  { className, children, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.RadioItem ref={ref} className={cn(itemClasses, 'pl-7', className)} {...props}>
      <span className="absolute left-2 flex size-3.5 items-center justify-center">
        <RadixDropdownMenu.ItemIndicator>
          <Circle className="size-2 fill-current" aria-hidden="true" />
        </RadixDropdownMenu.ItemIndicator>
      </span>
      {children}
    </RadixDropdownMenu.RadioItem>
  )
})

export const DropdownMenuLabel = forwardRef(function DropdownMenuLabel(
  { className, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.Label
      ref={ref}
      className={cn('px-2 py-1.5 text-xs font-semibold text-fg-muted', className)}
      {...props}
    />
  )
})

export const DropdownMenuSeparator = forwardRef(function DropdownMenuSeparator(
  { className, ...props },
  ref,
) {
  return (
    <RadixDropdownMenu.Separator
      ref={ref}
      className={cn('my-1 h-px bg-border-default', className)}
      {...props}
    />
  )
})
