import { Star } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Spinner } from '../../components/ui/Spinner'
import { mapStarsCheckoutError } from './starsErrors'
import { formatPackagePrice, formatStars } from './starsFormat'
import { useCreateStarsCheckoutSessionMutation } from './starsQueries'

/**
 * Real-money Stars top-ups. Same flow as the Premium subscription checkout:
 * create a session server-side, then hand the browser to Stripe's hosted page.
 */
export function StarsPackagesGrid({ packages }) {
  const { t } = useTranslation()
  const createSessionMutation = useCreateStarsCheckoutSessionMutation()
  const [pendingPackageId, setPendingPackageId] = useState(null)
  const [formError, setFormError] = useState('')

  const handleBuy = async (starsPackage) => {
    setFormError('')
    setPendingPackageId(starsPackage.Id)
    try {
      const session = await createSessionMutation.mutateAsync(starsPackage.Id)
      // Full-page redirect: Stripe Checkout is hosted cross-origin, so this can't
      // be a client-side router navigation. (`assign()` rather than setting
      // `location.href` - same behaviour, but it's a call instead of a write to
      // a global, which the react-hooks immutability rule rejects.)
      window.location.assign(session.Url)
    } catch (error) {
      setPendingPackageId(null)
      setFormError(mapStarsCheckoutError(t, error))
    }
  }

  if (!packages || packages.length === 0) {
    return <EmptyState icon={Star} title={t('stars.packages.empty')} />
  }

  return (
    <div className="flex flex-col gap-3">
      {formError && (
        <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}

      <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {packages.map((starsPackage) => {
          const stars = formatStars(starsPackage.Stars)
          const price = formatPackagePrice(starsPackage.PriceAmount, starsPackage.Currency)
          return (
            <li
              key={starsPackage.Id}
              className="flex flex-col gap-3 rounded-lg border border-border-default bg-surface-sidebar p-4"
            >
              <div className="flex items-center gap-2">
                <Star className="size-5 shrink-0 fill-current text-warning" aria-hidden="true" />
                <p className="text-lg font-semibold text-fg-heading">{stars}</p>
              </div>
              <p className="text-sm text-fg-muted">{t('stars.packages.starsLabel')}</p>
              <Button
                className="mt-auto w-full"
                onClick={() => handleBuy(starsPackage)}
                disabled={pendingPackageId !== null}
                aria-label={t('stars.packages.buyAriaLabel', { stars, price })}
              >
                {pendingPackageId === starsPackage.Id && <Spinner size="sm" />}
                {price}
              </Button>
            </li>
          )
        })}
      </ul>
    </div>
  )
}
