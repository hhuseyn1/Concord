import { useEffect, useRef } from 'react'

const STORAGE_PREFIX = 'concord:draft:'
const SAVE_DEBOUNCE_MS = 400

export function useDraftPersistence(draftKey, content) {
  const saveTimeoutRef = useRef(null)

  useEffect(() => {
    if (!draftKey) return undefined

    clearTimeout(saveTimeoutRef.current)
    saveTimeoutRef.current = setTimeout(() => {
      try {
        if (content) {
          localStorage.setItem(STORAGE_PREFIX + draftKey, content)
        } else {
          localStorage.removeItem(STORAGE_PREFIX + draftKey)
        }
      } catch {
      }
    }, SAVE_DEBOUNCE_MS)

    return () => clearTimeout(saveTimeoutRef.current)
  }, [draftKey, content])
}

export function readDraft(draftKey) {
  if (!draftKey) return ''
  try {
    return localStorage.getItem(STORAGE_PREFIX + draftKey) ?? ''
  } catch {
    return ''
  }
}

export function clearDraft(draftKey) {
  if (!draftKey) return
  try {
    localStorage.removeItem(STORAGE_PREFIX + draftKey)
  } catch {
  }
}
