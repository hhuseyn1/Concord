import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

export function CheckoutCancelScreen() {
  const { t } = useTranslation()

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
      <h1 className="text-lg font-semibold text-fg-heading">{t('billing.checkoutCanceledTitle')}</h1>
      <p className="text-sm text-fg-muted">{t('billing.checkoutCanceledDescription')}</p>
      <Link to="/cabinet/settings" className="font-medium text-brand hover:underline">
        {t('billing.backToSettings')}
      </Link>
    </div>
  )
}
