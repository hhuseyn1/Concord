import * as RadixTabs from '@radix-ui/react-tabs'
import { cn } from '../../lib/cn'

export const Tabs = RadixTabs.Root

export function TabsList({ className, ...props }) {
  return (
    <RadixTabs.List
      className={cn(
        'inline-flex max-w-full items-center gap-1 overflow-x-auto rounded-md bg-surface-sidebar p-1',
        className,
      )}
      {...props}
    />
  )
}

export function TabsTrigger({ className, ...props }) {
  return (
    <RadixTabs.Trigger
      className={cn(
        'rounded-sm px-3 py-1.5 text-sm font-medium text-fg-muted outline-none transition-colors duration-150',
        'hover:text-fg-default',
        'focus-visible:ring-2 focus-visible:ring-brand',
        'data-[state=active]:bg-surface-floating data-[state=active]:text-fg-default data-[state=active]:shadow-sm',
        className,
      )}
      {...props}
    />
  )
}

export function TabsContent({ className, ...props }) {
  return (
    <RadixTabs.Content
      className={cn('mt-3 outline-none focus-visible:ring-2 focus-visible:ring-brand', className)}
      {...props}
    />
  )
}
