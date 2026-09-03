import { Loader2 } from 'lucide-react'
import { cn } from '../../lib/cn'

const SIZES = {
  sm: 'size-4',
  md: 'size-6',
  lg: 'size-8',
}

export function Spinner({ size = 'md', label = 'Loading…', className }) {
  return (
    <span role="status" className={cn('inline-flex items-center text-fg-muted', className)}>
      <Loader2 className={cn('animate-spin', SIZES[size])} aria-hidden="true" />
      <span className="sr-only">{label}</span>
    </span>
  )
}
