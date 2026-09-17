import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

export const Input = forwardRef(function Input(
  { className, invalid = false, ...props },
  ref,
) {
  return (
    <input
      ref={ref}
      aria-invalid={invalid || undefined}
      className={cn(
        'w-full h-9 rounded-md border bg-surface-input px-3 text-base sm:text-sm text-fg-default placeholder:text-fg-muted',
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
