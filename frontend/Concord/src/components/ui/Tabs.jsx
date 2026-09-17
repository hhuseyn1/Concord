import * as RadixTabs from '@radix-ui/react-tabs'
import { useRef } from 'react'
import { cn } from '../../lib/cn'

export const Tabs = RadixTabs.Root

export function TabsList({ className, ...props }) {
  const listRef = useRef(null)

  const handleWheel = (event) => {
    const el = listRef.current
    if (!el || el.scrollWidth <= el.clientWidth) return
    if (Math.abs(event.deltaX) >= Math.abs(event.deltaY)) return
    event.preventDefault()
    el.scrollLeft += event.deltaY
  }

  return (
    <RadixTabs.List
      ref={listRef}
      onWheel={handleWheel}
      className={cn(
        'inline-flex max-w-full items-center gap-1 overflow-x-auto overscroll-x-contain rounded-md bg-surface-sidebar p-1',
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
        'shrink-0 rounded-sm px-3 py-1.5 text-sm font-medium whitespace-nowrap text-fg-muted outline-none transition-colors duration-150',
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
