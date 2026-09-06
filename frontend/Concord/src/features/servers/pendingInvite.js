import { useEffect } from 'react'

const STORAGE_KEY = 'concord.pendingInvite'
const TTL_MS = 24 * 60 * 60 * 1000

export function capturePendingInvite(code) {
  if (!code) return
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ code, savedAt: Date.now() }))
  } catch {
    // localStorage unavailable (private mode, etc.) - invite just won't survive a detour
  }
}

export function getPendingInvite() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed?.code || Date.now() - parsed.savedAt > TTL_MS) {
      clearPendingInvite()
      return null
    }
    return parsed.code
  } catch {
    return null
  }
}

export function clearPendingInvite() {
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch {
    // ignore
  }
}

export function useCapturePendingInviteFromUrl(searchParams) {
  useEffect(() => {
    const code = searchParams.get('invite')
    if (code) capturePendingInvite(code)
  }, [searchParams])
}
