import { Check, Type } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { useFontSize } from '../../hooks/useAppearance'
import { FONT_SIZES, setFontSize } from '../../lib/fontSize'

const LABEL_KEYS = {
  small: 'appearance.fontSizeSmall',
  default: 'appearance.fontSizeDefault',
  large: 'appearance.fontSizeLarge',
  xl: 'appearance.fontSizeExtraLarge',
}

export function FontSizeControl() {
  const { t } = useTranslation()
  const fontSize = useFontSize()

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-sm font-medium text-fg-default">{t('appearance.fontSize')}</p>
          <p className="text-xs text-fg-muted">{t('appearance.fontSizeHint')}</p>
        </div>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="secondary" size="sm" className="shrink-0">
              <Type className="size-4" aria-hidden="true" />
              {t(LABEL_KEYS[fontSize] ?? LABEL_KEYS.default, {
                px: FONT_SIZES.find((option) => option.value === fontSize)?.px ?? 14,
              })}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuRadioGroup value={fontSize} onValueChange={setFontSize}>
              {FONT_SIZES.map((option) => (
                <DropdownMenuRadioItem key={option.value} value={option.value}>
                  {t(LABEL_KEYS[option.value], { px: option.px })}
                </DropdownMenuRadioItem>
              ))}
            </DropdownMenuRadioGroup>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <div className="flex items-start gap-2 rounded-md border border-border-subtle bg-surface-sidebar p-3">
        <Check className="mt-0.5 size-4 shrink-0 text-success" aria-hidden="true" />
        <div className="min-w-0">
          <p className="text-base text-fg-default">{t('appearance.fontSizePreview')}</p>
          <p className="text-xs text-fg-faint">{t('appearance.fontSizePreviewMeta')}</p>
        </div>
      </div>
    </div>
  )
}
