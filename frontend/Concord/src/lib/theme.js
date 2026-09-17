/*
 * Theme preference (dark/light) - module-level state with a subscribe/notify
 * channel, mirroring `api/tokenStorage.js`, so every mounted consumer (the
 * landing navbar toggle, the Settings > Appearance toggle, ...) stays in sync
 * within a session no matter where the change came from.
 *
 * STORAGE_KEY and the accepted values must stay identical to the anti-FOUC
 * inline script in index.html, which applies the attribute before React mounts.
 * This module never *needs* to paint on load - it just adopts whatever the
 * inline script already decided - but it re-applies defensively so the app is
 * still correct if that script is ever removed or fails.
 */

const STORAGE_KEY = 'concord.theme'
const ATTRIBUTE = 'data-theme'

export const THEMES = ['dark', 'light']

const listeners = new Set()

function isTheme(value) {
  return THEMES.includes(value)
}

function readStoredTheme() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    return isTheme(stored) ? stored : null
  } catch {
    return null
  }
}

function systemTheme() {
  return window.matchMedia?.('(prefers-color-scheme: light)').matches ? 'light' : 'dark'
}

function applyTheme(theme) {
  document.documentElement.setAttribute(ATTRIBUTE, theme)
}

// `null` until the user explicitly picks a theme; while it's null we keep
// following the OS preference.
let explicitTheme = readStoredTheme()
let currentTheme = explicitTheme ?? systemTheme()

applyTheme(currentTheme)

function notifyListeners() {
  for (const listener of listeners) listener(currentTheme)
}

function setCurrentTheme(theme) {
  if (currentTheme === theme) return
  currentTheme = theme
  applyTheme(currentTheme)
  notifyListeners()
}

// Keep following the OS while the user hasn't made a choice of their own -
// e.g. macOS/Windows auto-switching at sunset with Concord already open.
window.matchMedia?.('(prefers-color-scheme: light)').addEventListener?.('change', () => {
  if (explicitTheme) return
  setCurrentTheme(systemTheme())
})

export function getTheme() {
  return currentTheme
}

export function hasExplicitThemeChoice() {
  return explicitTheme !== null
}

export function setTheme(theme) {
  if (!isTheme(theme)) return

  explicitTheme = theme
  try {
    localStorage.setItem(STORAGE_KEY, theme)
  } catch {
    // Storage unavailable: the choice still applies for this session.
  }
  setCurrentTheme(theme)
}

export function toggleTheme() {
  setTheme(currentTheme === 'dark' ? 'light' : 'dark')
}

export function subscribe(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}
