import { Moon, Sun } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { useTheme } from '../../hooks/useAppearance'
import { cn } from '../../lib/cn'
import { toggleTheme } from '../../lib/theme'
import { IconButton } from './IconButton'
import { Tooltip } from './Tooltip'

/**
 * Explicit dark/light switch. Reads and writes the single module-level theme
 * store (`lib/theme.js`), so every instance - landing navbar, Settings >
 * Appearance - shows the same state and stays in sync when any one of them is
 * used.
 */
export function ThemeToggle({ className, size = 'md', ...props }) {
  const { t } = useTranslation()
  const theme = useTheme()
  const isDark = theme === 'dark'
  // Labels the *action*, not the current state - that's what a screen-reader
  // user needs from a button.
  const label = isDark ? t('appearance.switchToLight') : t('appearance.switchToDark')

  return (
    <Tooltip content={label}>
      <IconButton
        aria-label={label}
        variant="ghost"
        size={size}
        onClick={toggleTheme}
        // Comfortable >=40px touch target on phones; the tighter 36px desktop
        // sizing takes over from `sm` up.
        className={cn('max-sm:h-10 max-sm:w-10', className)}
        {...props}
      >
        {isDark ? <Sun className="size-4" aria-hidden="true" /> : <Moon className="size-4" aria-hidden="true" />}
      </IconButton>
    </Tooltip>
  )
}
