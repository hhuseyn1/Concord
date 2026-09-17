
const STORAGE_KEY = 'concord.fontSize'
const ATTRIBUTE = 'data-font-size'

export const DEFAULT_FONT_SIZE = 'default'

export const FONT_SIZES = [
  { value: 'small', px: 14 },
  { value: 'default', px: 15 },
  { value: 'large', px: 17 },
  { value: 'xl', px: 19 },
]

const listeners = new Set()

function isFontSize(value) {
  return FONT_SIZES.some((option) => option.value === value)
}

function readStoredFontSize() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    return isFontSize(stored) ? stored : null
  } catch {
    return null
  }
}

function applyFontSize(fontSize) {
  document.documentElement.setAttribute(ATTRIBUTE, fontSize)
}

let currentFontSize = readStoredFontSize() ?? DEFAULT_FONT_SIZE

applyFontSize(currentFontSize)

export function getFontSize() {
  return currentFontSize
}

export function setFontSize(fontSize) {
  if (!isFontSize(fontSize) || fontSize === currentFontSize) return

  currentFontSize = fontSize
  applyFontSize(currentFontSize)
  try {
    localStorage.setItem(STORAGE_KEY, currentFontSize)
  } catch {
  }
  for (const listener of listeners) listener(currentFontSize)
}

export function subscribe(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}
