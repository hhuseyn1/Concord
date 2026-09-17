import { cn } from '../../lib/cn'

export function AuthLayout({ title, subtitle, children, footer, className }) {
  return (
    <div className="flex min-h-dvh w-full items-center justify-center bg-surface-rail p-4">
      <div className={cn('w-full max-w-sm rounded-lg bg-surface-sidebar p-8 shadow-lg', className)}>
        <div className="mb-6 flex flex-col items-center gap-3 text-center">
          {/* The app-icon asset already has its own brand-blue rounded-square badge baked in
            * (unlike the old logo, this one isn't near-white/monochrome) - wrapping it in another
            * `bg-brand` badge here would stack near-identical blues with no contrast between them. */}
          <img src="/logo-app-icon.png" alt="" className="size-12 shrink-0 rounded-2xl" aria-hidden="true" />
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
