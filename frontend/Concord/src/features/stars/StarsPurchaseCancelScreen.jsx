import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { STARS_SETTINGS_PATH } from './starsRoutes'

export function StarsPurchaseCancelScreen() {
  const { t } = useTranslation()

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
      <h1 className="text-lg font-semibold text-fg-heading">{t('stars.purchase.canceledTitle')}</h1>
      <p className="max-w-md text-sm text-fg-muted">{t('stars.purchase.canceledDescription')}</p>
      <Link to={STARS_SETTINGS_PATH} className="font-medium text-brand hover:underline">
        {t('stars.purchase.backToStars')}
      </Link>
    </div>
  )
}
