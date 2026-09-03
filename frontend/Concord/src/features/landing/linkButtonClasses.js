import { cn } from '../../lib/cn'

/**
 * Mirrors components/ui/Button's visual language for `<Link>`s that need to look like a button
 * (react-router navigation, not a click handler, so the real `Button` - a plain `<button>` - isn't
 * a fit). Kept local to the landing page rather than changing Button's public API for one caller.
 */
const BASE =
  'inline-flex items-center justify-center gap-2 rounded-md font-medium ' +
  'transition-colors duration-150 [transition-timing-function:var(--ease-standard)] ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-base'

const VARIANTS = {
  primary: 'bg-brand text-fg-on-brand hover:bg-brand-hover active:bg-brand-pressed',
  secondary: 'bg-fg-default/10 text-fg-default hover:bg-fg-default/15 active:bg-fg-default/20',
  ghost: 'bg-transparent text-fg-default hover:bg-fg-default/10 active:bg-fg-default/15',
}

const SIZES = {
  md: 'h-9 px-4 text-sm',
  lg: 'h-11 px-6 text-base',
  xl: 'h-13 px-7 text-base',
}

export function linkButtonClasses(variant = 'primary', size = 'md', className) {
  return cn(BASE, VARIANTS[variant], SIZES[size], className)
}
