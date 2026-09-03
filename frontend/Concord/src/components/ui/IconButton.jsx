import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

const VARIANTS = {
  primary: 'bg-brand text-fg-on-brand hover:bg-brand-hover active:bg-brand-pressed',
  secondary:
    'bg-fg-default/10 text-fg-default hover:bg-fg-default/15 active:bg-fg-default/20',
  ghost: 'bg-transparent text-fg-muted hover:bg-fg-default/10 hover:text-fg-default',
  danger:
    'bg-danger-solid text-fg-on-danger hover:bg-danger-solid-hover active:bg-danger-solid-pressed',
}

const SIZES = {
  sm: 'h-8 w-8 [&_svg]:size-4',
  md: 'h-9 w-9 [&_svg]:size-[1.125rem]',
  lg: 'h-11 w-11 [&_svg]:size-5',
}

export const IconButton = forwardRef(function IconButton(
  { variant = 'ghost', size = 'md', className, type = 'button', ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cn(
        'inline-flex items-center justify-center rounded-md transition-colors duration-150 [transition-timing-function:var(--ease-standard)]',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-base',
        'disabled:opacity-50 disabled:pointer-events-none',
        VARIANTS[variant],
        SIZES[size],
        className,
      )}
      {...props}
    />
  )
})
