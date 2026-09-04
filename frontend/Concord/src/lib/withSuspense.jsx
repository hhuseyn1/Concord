import { Suspense } from 'react'
import { RouteFallback } from '../components/layout/RouteFallback'

export function withSuspense(element) {
  return <Suspense fallback={<RouteFallback />}>{element}</Suspense>
}
