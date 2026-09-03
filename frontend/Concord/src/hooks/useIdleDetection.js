import { useEffect, useRef } from 'react'

const ACTIVITY_EVENTS = ['mousemove', 'keydown', 'mousedown', 'touchstart', 'scroll']
const RESET_THROTTLE_MS = 10_000

export function useIdleDetection({ enabled, onIdle, onActive, idleTimeoutMs = 5 * 60 * 1000 }) {
  const timeoutRef = useRef(null)
  const lastResetAtRef = useRef(0)
  const onIdleRef = useRef(onIdle)
  const onActiveRef = useRef(onActive)

  useEffect(() => {
    onIdleRef.current = onIdle
    onActiveRef.current = onActive
  }, [onIdle, onActive])

  useEffect(() => {
    if (!enabled) return undefined

    const resetTimer = () => {
      const now = Date.now()
      if (now - lastResetAtRef.current < RESET_THROTTLE_MS) return
      lastResetAtRef.current = now

      onActiveRef.current?.()
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
      timeoutRef.current = setTimeout(() => onIdleRef.current?.(), idleTimeoutMs)
    }

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') resetTimer()
    }

    for (const event of ACTIVITY_EVENTS) {
      window.addEventListener(event, resetTimer, { passive: true })
    }
    document.addEventListener('visibilitychange', handleVisibilityChange)

    resetTimer()

    return () => {
      for (const event of ACTIVITY_EVENTS) {
        window.removeEventListener(event, resetTimer)
      }
      document.removeEventListener('visibilitychange', handleVisibilityChange)
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
    }
  }, [enabled, idleTimeoutMs])
}
