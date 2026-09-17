import { Moon, Sun } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { useTheme } from '../../hooks/useAppearance'
import { cn } from '../../lib/cn'
import { toggleTheme } from '../../lib/theme'
import { IconButton } from './IconButton'
import { Tooltip } from './Tooltip'

export function ThemeToggle({ className, size = 'md', ...props }) {
  const { t } = useTranslation()
  const theme = useTheme()
  const isDark = theme === 'dark'
  const label = isDark ? t('appearance.switchToLight') : t('appearance.switchToDark')

  return (
    <Tooltip content={label}>
      <IconButton
        aria-label={label}
        variant="ghost"
        size={size}
        onClick={toggleTheme}
        className={cn('max-sm:h-10 max-sm:w-10', className)}
        {...props}
      >
        {isDark ? <Sun className="size-4" aria-hidden="true" /> : <Moon className="size-4" aria-hidden="true" />}
      </IconButton>
    </Tooltip>
  )
}
