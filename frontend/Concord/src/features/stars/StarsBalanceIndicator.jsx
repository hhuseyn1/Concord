import { Star } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { Tooltip } from '../../components/ui/Tooltip'
import { cn } from '../../lib/cn'
import { formatStars } from './starsFormat'
import { STARS_SETTINGS_PATH } from './starsRoutes'
import { useStarsWallet } from './starsQueries'

export function StarsBalanceIndicator({ className }) {
  const { t } = useTranslation()
  const { data: wallet, isSuccess } = useStarsWallet()

  if (!isSuccess) return null

  const balance = formatStars(wallet?.Balance ?? 0)

  return (
    <Tooltip content={t('stars.indicator.tooltip', { amount: balance })} side="top">
      <Link
        to={STARS_SETTINGS_PATH}
        aria-label={t('stars.indicator.ariaLabel', { amount: balance })}
        className={cn(
          'flex shrink-0 items-center gap-1 rounded-full bg-fg-default/10 px-2 py-0.5 text-xs font-medium text-fg-default no-underline',
          'transition-colors duration-150 hover:bg-fg-default/15',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand',
          className,
        )}
      >
        <Star className="size-3 shrink-0 fill-current text-warning" aria-hidden="true" />
        <span className="tabular-nums">{balance}</span>
      </Link>
    </Tooltip>
  )
}
