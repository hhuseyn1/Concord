import * as RadixToast from '@radix-ui/react-toast'
import { CheckCircle2, Info, TriangleAlert, X, XCircle } from 'lucide-react'
import { useCallback, useEffect, useState } from 'react'
import { cn } from '../../lib/cn'
import { Avatar } from './Avatar'

let listeners = []
let idCounter = 0
const activeDedupeKeys = new Set()

const ICONS = {
  success: CheckCircle2,
  danger: XCircle,
  warning: TriangleAlert,
  info: Info,
}

const ICON_CLASSES = {
  success: 'text-success',
  danger: 'text-danger',
  warning: 'text-warning',
  info: 'text-info',
}

export function toast({ title, description, variant = 'info', duration = 5000, avatarSrc, avatarName, onClick, dedupeKey } = {}) {
  if (dedupeKey) {
    if (activeDedupeKeys.has(dedupeKey)) return undefined
    activeDedupeKeys.add(dedupeKey)
  }
  const id = ++idCounter
  listeners.forEach((listener) =>
    listener({ id, title, description, variant, duration, avatarSrc, avatarName, onClick, dedupeKey }),
  )
  return id
}

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([])

  const dismiss = useCallback((id) => {
    setToasts((current) => {
      const dismissed = current.find((item) => item.id === id)
      if (dismissed?.dedupeKey) activeDedupeKeys.delete(dismissed.dedupeKey)
      return current.filter((item) => item.id !== id)
    })
  }, [])

  useEffect(() => {
    const handler = (next) => setToasts((current) => [...current, next])
    listeners.push(handler)
    return () => {
      listeners = listeners.filter((listener) => listener !== handler)
    }
  }, [])

  return (
    <RadixToast.Provider swipeDirection="right">
      {children}
      {toasts.map((item) => {
        const Icon = ICONS[item.variant] ?? Info
        const hasAvatar = Boolean(item.avatarSrc || item.avatarName)
        return (
          <RadixToast.Root
            key={item.id}
            duration={item.duration}
            onOpenChange={(open) => {
              if (!open) dismiss(item.id)
            }}
            className={cn(
              'flex items-start gap-3 rounded-md border border-border-default bg-surface-floating p-4 shadow-lg',
              'motion-safe:data-[state=open]:animate-toast-in motion-safe:data-[state=closed]:animate-toast-out',
              'data-[swipe=end]:translate-x-[var(--radix-toast-swipe-end-x)]',
            )}
          >
            {hasAvatar ? (
              <Avatar src={item.avatarSrc} name={item.avatarName} size="sm" className="mt-0.5 shrink-0" />
            ) : (
              <Icon className={cn('mt-0.5 size-5 shrink-0', ICON_CLASSES[item.variant])} aria-hidden="true" />
            )}
            <div
              className={cn('flex-1 min-w-0', item.onClick && 'cursor-pointer')}
              role={item.onClick ? 'button' : undefined}
              tabIndex={item.onClick ? 0 : undefined}
              onClick={() => {
                if (!item.onClick) return
                item.onClick()
                dismiss(item.id)
              }}
              onKeyDown={(event) => {
                if (!item.onClick) return
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  item.onClick()
                  dismiss(item.id)
                }
              }}
            >
              {item.title && (
                <RadixToast.Title className="text-sm font-semibold text-fg-default">
                  {item.title}
                </RadixToast.Title>
              )}
              {item.description && (
                <RadixToast.Description className="text-sm text-fg-muted">
                  {item.description}
                </RadixToast.Description>
              )}
            </div>
            <RadixToast.Close
              aria-label="Dismiss"
              className="shrink-0 text-fg-muted transition-colors duration-150 hover:text-fg-default"
            >
              <X className="size-4" aria-hidden="true" />
            </RadixToast.Close>
          </RadixToast.Root>
        )
      })}
      <RadixToast.Viewport className="fixed bottom-0 right-0 z-50 flex w-96 max-w-[100vw] flex-col gap-2 p-6 outline-none" />
    </RadixToast.Provider>
  )
}
