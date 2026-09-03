import * as RadixAvatar from '@radix-ui/react-avatar'
import { getApiBaseUrl } from '../../api/httpClient'
import { cn } from '../../lib/cn'

const SIZES = {
  sm: 'size-8 text-xs',
  md: 'size-10 text-sm',
  lg: 'size-12 text-base',
  xl: 'size-16 text-lg',
}

const PRESENCE_COLOR = {
  online: 'bg-presence-online',
  idle: 'bg-presence-idle',
  dnd: 'bg-presence-dnd',
  offline: 'bg-presence-offline',
}

const PRESENCE_DOT_SIZE = {
  sm: 'size-2.5',
  md: 'size-3',
  lg: 'size-3.5',
  xl: 'size-4',
}

const SHAPE = {
  circle: 'rounded-full',
  squircle: 'rounded-2xl',
}

export function Avatar({ src, alt = '', name, size = 'md', presence, shape = 'circle', className }) {
  const initials = name
    ? name
        .trim()
        .split(/\s+/)
        .slice(0, 2)
        .map((part) => part[0]?.toUpperCase())
        .join('')
    : ''

  const resolvedSrc = src?.startsWith('/') ? `${getApiBaseUrl()}${src}` : src

  return (
    <span className={cn('relative inline-flex shrink-0', SIZES[size], className)}>
      <RadixAvatar.Root
        className={cn(
          'flex size-full items-center justify-center overflow-hidden bg-surface-rail font-medium text-fg-default select-none',
          SHAPE[shape],
        )}
      >
        <RadixAvatar.Image src={resolvedSrc} alt={alt} className="size-full object-cover" />
        <RadixAvatar.Fallback delayMs={src ? 300 : 0} className="flex items-center justify-center">
          {initials || <span className="sr-only">{alt || 'User'}</span>}
        </RadixAvatar.Fallback>
      </RadixAvatar.Root>
      {presence && (
        <span
          aria-label={`Status: ${presence}`}
          className={cn(
            'absolute right-0 bottom-0 rounded-full ring-2 ring-surface-base',
            PRESENCE_COLOR[presence],
            PRESENCE_DOT_SIZE[size],
          )}
        />
      )}
    </span>
  )
}
