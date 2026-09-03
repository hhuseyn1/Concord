import * as RadixScrollArea from '@radix-ui/react-scroll-area'
import { cn } from '../../lib/cn'

export function ScrollArea({
  className,
  viewportClassName,
  orientation = 'vertical',
  viewportRef,
  children,
  ...props
}) {
  return (
    <RadixScrollArea.Root className={cn('overflow-hidden', className)} {...props}>
      <RadixScrollArea.Viewport ref={viewportRef} className={cn('size-full', viewportClassName)}>
        {children}
      </RadixScrollArea.Viewport>
      {(orientation === 'vertical' || orientation === 'both') && (
        <RadixScrollArea.Scrollbar
          orientation="vertical"
          className="flex w-2.5 touch-none select-none p-0.5 transition-colors duration-150 data-[state=hidden]:opacity-0"
        >
          <RadixScrollArea.Thumb className="relative flex-1 rounded-full bg-fg-default/20" />
        </RadixScrollArea.Scrollbar>
      )}
      {(orientation === 'horizontal' || orientation === 'both') && (
        <RadixScrollArea.Scrollbar
          orientation="horizontal"
          className="flex h-2.5 touch-none select-none p-0.5 transition-colors duration-150 data-[state=hidden]:opacity-0"
        >
          <RadixScrollArea.Thumb className="relative flex-1 rounded-full bg-fg-default/20" />
        </RadixScrollArea.Scrollbar>
      )}
      <RadixScrollArea.Corner />
    </RadixScrollArea.Root>
  )
}
