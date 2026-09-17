import { useSyncExternalStore } from 'react'
import * as fontSizeStore from '../lib/fontSize'
import * as themeStore from '../lib/theme'

/**
 * Read the live theme / font-size preference from the module-level stores in
 * `lib/theme.js` and `lib/fontSize.js`. `useSyncExternalStore` keeps every
 * mount point (landing navbar, Settings > Appearance, ...) in sync from the
 * single source of truth, so a toggle in one place updates the other instantly.
 */
export function useTheme() {
  return useSyncExternalStore(themeStore.subscribe, themeStore.getTheme, () => 'dark')
}

export function useFontSize() {
  return useSyncExternalStore(
    fontSizeStore.subscribe,
    fontSizeStore.getFontSize,
    () => fontSizeStore.DEFAULT_FONT_SIZE,
  )
}
