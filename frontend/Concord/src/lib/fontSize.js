/*
 * Font-size (accessibility) preference - same module-level, subscribable
 * persisted-state pattern as `lib/theme.js`.
 *
 * The value only ever drives the `data-font-size` attribute on <html>, which
 * `styles/tokens.css` turns into a `--font-scale` multiplier over the `--text-*`
 * ramp. Nothing here touches the root font-size, so Tailwind's rem-based
 * spacing/sizing scale is unaffected.
 *
 * STORAGE_KEY and the accepted values must stay identical to the anti-FOUC
 * inline script in index.html.
 */

const STORAGE_KEY = 'concord.fontSize'
const ATTRIBUTE = 'data-font-size'

export const DEFAULT_FONT_SIZE = 'default'

// `px` is the *rendered* body-text size each option produces, used only for the
// human-readable labels in Settings ("Large (17px)"). Concord's default body
// step (`--text-base`) is 15px, so applying the 13/14, 16/14 and 18/14 scale
// ratios lands on 14 / 15 / 17 / 19px rather than a flat 13/14/16/18 - these
// numbers are the honest ones a user can measure on screen.
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
    // Storage unavailable: the choice still applies for this session.
  }
  for (const listener of listeners) listener(currentFontSize)
}

export function subscribe(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}
