import { Languages } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { cn } from '../../lib/cn'
import { setLanguage } from '../../i18n'
import { LANGUAGE_LABELS } from '../../i18n/localeMapping'

/**
 * Compact language picker for the (unauthenticated) landing navbar.
 *
 * Deliberately NOT `features/settings/LanguageSwitcher.jsx`: that one also
 * persists the choice to the backend via the preferences mutation, which
 * requires a signed-in user. Here the localStorage-backed `setLanguage()` is
 * the whole job - if the visitor later signs in and changes the language from
 * Settings, that's when it gets written to their account.
 */
export function LandingLanguageSwitcher({ className }) {
  const { t, i18n } = useTranslation()
  const currentLabel = LANGUAGE_LABELS[i18n.language] ?? LANGUAGE_LABELS.en

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          aria-label={t('settings.language')}
          className={cn('max-sm:h-10', className)}
        >
          <Languages className="size-4" aria-hidden="true" />
          <span className="font-medium">{currentLabel.short}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuRadioGroup value={i18n.language} onValueChange={setLanguage}>
          {Object.entries(LANGUAGE_LABELS).map(([code, label]) => (
            <DropdownMenuRadioItem key={code} value={code}>
              {label.long}
            </DropdownMenuRadioItem>
          ))}
        </DropdownMenuRadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
