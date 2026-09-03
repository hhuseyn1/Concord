import { useTranslation } from 'react-i18next'

const IS_MAC = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform ?? navigator.userAgent ?? '')
const MOD_KEY = IS_MAC ? '⌘' : 'Ctrl'

const SHORTCUTS = [
  { keys: [MOD_KEY, 'K'], labelKey: 'shortcuts.search' },
  { keys: ['Esc'], labelKey: 'shortcuts.closeDialog' },
  { keys: ['Enter'], labelKey: 'shortcuts.sendMessage' },
  { keys: ['Shift', 'Enter'], labelKey: 'shortcuts.newLine' },
  { keys: [MOD_KEY, 'Shift', 'M'], labelKey: 'shortcuts.toggleMute' },
  { keys: [MOD_KEY, 'Shift', 'D'], labelKey: 'shortcuts.toggleDeafen' },
]

export function ShortcutsSection() {
  const { t } = useTranslation()

  return (
    <div>
      <h2 className="mb-4 text-sm font-semibold text-fg-heading">{t('shortcuts.title')}</h2>
      <div className="flex flex-col gap-2">
        {SHORTCUTS.map((shortcut) => (
          <div key={shortcut.labelKey} className="flex items-center justify-between text-sm">
            <span className="text-fg-default">{t(shortcut.labelKey)}</span>
            <span className="flex items-center gap-1">
              {shortcut.keys.map((key) => (
                <kbd
                  key={key}
                  className="rounded border border-border-default bg-surface-sidebar px-1.5 py-0.5 text-xs font-medium text-fg-muted"
                >
                  {key}
                </kbd>
              ))}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
