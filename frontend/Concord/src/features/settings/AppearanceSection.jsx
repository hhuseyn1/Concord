import { useTranslation } from 'react-i18next'
import { ThemeToggle } from '../../components/ui/ThemeToggle'
import { useTheme } from '../../hooks/useAppearance'
import { FontSizeControl } from './FontSizeControl'

export function AppearanceSection() {
  const { t } = useTranslation()
  const theme = useTheme()

  return (
    <div className="flex max-w-md flex-col gap-4">
      <div>
        <h2 className="text-sm font-semibold text-fg-heading">{t('appearance.title')}</h2>
        <p className="text-xs text-fg-muted">{t('appearance.description')}</p>
      </div>

      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-sm font-medium text-fg-default">{t('appearance.theme')}</p>
          <p className="text-xs text-fg-muted">
            {theme === 'dark' ? t('appearance.darkActive') : t('appearance.lightActive')}
          </p>
        </div>
        <ThemeToggle className="shrink-0" />
      </div>

      <FontSizeControl />
    </div>
  )
}
