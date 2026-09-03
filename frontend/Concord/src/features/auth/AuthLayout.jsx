import { cn } from '../../lib/cn'

export function AuthLayout({ title, subtitle, children, footer, className }) {
  return (
    <div className="flex min-h-dvh w-full items-center justify-center bg-surface-rail p-4">
      <div className={cn('w-full max-w-sm rounded-lg bg-surface-sidebar p-8 shadow-lg', className)}>
        <div className="mb-6 flex flex-col items-center gap-3 text-center">
          <span
            aria-hidden="true"
            className="flex size-12 shrink-0 items-center justify-center rounded-2xl bg-brand text-lg font-semibold text-fg-on-brand"
          >
            C
          </span>
          <div>
            <h1 className="text-xl font-semibold text-fg-heading">{title}</h1>
            {subtitle && <p className="mt-1 text-sm text-fg-muted">{subtitle}</p>}
          </div>
        </div>

        {children}

        {footer && <div className="mt-6 text-center text-sm text-fg-muted">{footer}</div>}
      </div>
    </div>
  )
}
