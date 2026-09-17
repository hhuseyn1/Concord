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
