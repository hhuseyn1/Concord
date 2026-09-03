import { cn } from '../../lib/cn'

export function Skeleton({ className, ...props }) {
  return (
    <div
      aria-hidden="true"
      className={cn('animate-pulse rounded-md bg-fg-default/10', className)}
      {...props}
    />
  )
}
