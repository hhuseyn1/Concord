import { useSyncExternalStore } from 'react'
import * as fontSizeStore from '../lib/fontSize'
import * as themeStore from '../lib/theme'

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
