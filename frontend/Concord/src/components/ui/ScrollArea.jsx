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
      {/* Radix wraps the viewport's children in a `display: table; min-width: 100%` div so that
        * content wider than the box still stretches the scrollable area. For a vertically
        * scrolling column (message lists, sidebars) that shrink-to-fit table box is wrong: rows
        * size to their widest line instead of to the viewport, so long messages run off the edge
        * on a narrow screen instead of wrapping. Forcing it back to a plain block restores normal
        * block-level width behaviour; horizontal scrolling isn't used with this primitive. */}
      <RadixScrollArea.Viewport
        ref={viewportRef}
        className={cn('size-full [&>div]:!block', viewportClassName)}
      >
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
