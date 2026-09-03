import { forwardRef } from 'react'
import { cn } from '../../lib/cn'

const BASE =
  'inline-flex items-center justify-center gap-2 rounded-md font-medium ' +
  'transition-colors duration-150 [transition-timing-function:var(--ease-standard)] ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-base ' +
  'disabled:opacity-50 disabled:pointer-events-none'

const VARIANTS = {
  primary: 'bg-brand text-fg-on-brand hover:bg-brand-hover active:bg-brand-pressed',
  secondary:
    'bg-fg-default/10 text-fg-default hover:bg-fg-default/15 active:bg-fg-default/20',
  ghost: 'bg-transparent text-fg-default hover:bg-fg-default/10 active:bg-fg-default/15',
  danger:
    'bg-danger-solid text-fg-on-danger hover:bg-danger-solid-hover active:bg-danger-solid-pressed',
  link: 'bg-transparent text-brand hover:underline p-0 h-auto',
}

const SIZES = {
  sm: 'h-8 px-3 text-xs',
  md: 'h-9 px-4 text-sm',
  lg: 'h-11 px-5 text-base',
}

export const Button = forwardRef(function Button(
  { variant = 'primary', size = 'md', className, type = 'button', ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cn(
        BASE,
        VARIANTS[variant],
        variant !== 'link' && SIZES[size],
        variant === 'link' && 'text-sm',
        className,
      )}
      {...props}
    />
  )
})
