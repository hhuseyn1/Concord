import { cn } from '../../lib/cn'

const VARIANTS = {
  neutral: 'bg-fg-default/10 text-fg-default',
  brand: 'bg-brand-bg text-brand',
  danger: 'bg-danger-bg text-danger',
  success: 'bg-success-bg text-success',
  warning: 'bg-warning-bg text-warning',
  info: 'bg-info-bg text-info',
}

export function Badge({ variant = 'neutral', className, children, ...props }) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium leading-none',
        VARIANTS[variant],
        className,
      )}
      {...props}
    >
      {children}
    </span>
  )
}
