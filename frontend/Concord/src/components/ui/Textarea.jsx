import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

export const Textarea = forwardRef(function Textarea(
  { className, invalid = false, rows = 3, ...props },
  ref,
) {
  return (
    <textarea
      ref={ref}
      rows={rows}
      aria-invalid={invalid || undefined}
      className={cn(
        // text-base below `sm` is load-bearing (see Input.jsx) - iOS Safari zooms in on focus for
        // any field under 16px, which is what makes the chat composer trigger the "opens zoomed
        // in" bug on a phone.
        'w-full min-h-9 resize-y rounded-md border bg-surface-sidebar px-3 py-2 text-base sm:text-sm text-fg-default placeholder:text-fg-muted',
        'transition-colors duration-150 [transition-timing-function:var(--ease-standard)]',
        'outline-none focus-visible:ring-2 focus-visible:ring-brand',
        'disabled:opacity-50 disabled:pointer-events-none',
        invalid
          ? 'border-danger focus-visible:ring-danger'
          : 'border-border-default focus-visible:border-brand',
        className,
      )}
      {...props}
    />
  )
})
