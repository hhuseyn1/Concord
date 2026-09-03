import { cn } from '../../lib/cn'

export function EmptyState({ icon: Icon, title, description, action, compact = false, className }) {
  if (compact) {
    return (
      <div className={cn('flex flex-col gap-0.5 px-2 py-1.5 text-left', className)}>
        <p className="text-sm text-fg-muted">{title}</p>
        {description && <p className="text-xs text-fg-muted">{description}</p>}
        {action}
      </div>
    )
  }

  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center gap-3 rounded-lg border border-dashed border-border-default px-6 py-12 text-center',
        className,
      )}
    >
      {Icon && (
        <span className="flex size-12 items-center justify-center rounded-full bg-fg-default/10 text-fg-muted">
          <Icon className="size-6" aria-hidden="true" />
        </span>
      )}
      <div className="flex flex-col gap-1">
        <p className="text-sm font-semibold text-fg-heading">{title}</p>
        {description && <p className="text-sm text-fg-muted">{description}</p>}
      </div>
      {action}
    </div>
  )
}
