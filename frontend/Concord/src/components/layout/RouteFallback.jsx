import { Spinner } from '../ui/Spinner'

export function RouteFallback() {
  return (
    <div className="flex min-h-dvh items-center justify-center bg-surface-base">
      <Spinner size="lg" />
    </div>
  )
}
