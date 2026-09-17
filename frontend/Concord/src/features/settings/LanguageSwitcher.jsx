import { Languages } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { Button } from '../../components/ui/Button'
import { setLanguage } from '../../i18n'
import { LANGUAGE_LABELS, toServerLocale } from '../../i18n/localeMapping'
import { useUpdatePreferencesMutation } from './settingsQueries'
import { useAuth } from '../../hooks/useAuth'

export function LanguageSwitcher() {
  const { t, i18n } = useTranslation()
  const { user } = useAuth()
  const updatePreferencesMutation = useUpdatePreferencesMutation()

  const handleChange = (nextLanguage) => {
    setLanguage(nextLanguage)
    if (!user) return
    updatePreferencesMutation.mutate({
      Locale: toServerLocale(nextLanguage),
      NotificationsMuted: user.NotificationsMuted,
      NotificationsSoundEnabled: user.NotificationsSoundEnabled,
    })
  }

  return (
    <div className="flex items-center justify-between gap-3">
      <div>
        <p className="text-sm font-medium text-fg-default">{t('settings.language')}</p>
      </div>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="secondary" size="sm">
            <Languages className="size-4" aria-hidden="true" />
            {(LANGUAGE_LABELS[i18n.language] ?? LANGUAGE_LABELS.az).long}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuRadioGroup value={i18n.language} onValueChange={handleChange}>
            {Object.entries(LANGUAGE_LABELS).map(([code, label]) => (
              <DropdownMenuRadioItem key={code} value={code}>
                {label.long}
              </DropdownMenuRadioItem>
            ))}
          </DropdownMenuRadioGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}
