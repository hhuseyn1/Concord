
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
