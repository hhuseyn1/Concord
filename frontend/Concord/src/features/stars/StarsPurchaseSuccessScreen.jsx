import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import * as starsService from '../../api/starsService'
import { Spinner } from '../../components/ui/Spinner'
import { starsKeys } from './starsQueries'
import { STARS_SETTINGS_PATH } from './starsRoutes'

const POLL_INTERVAL_MS = 2000
// Best-effort cutoff, matching the Premium checkout screen: long enough to ride
// out a slow Stripe -> backend confirmation, short enough not to spin forever.
const POLL_TIMEOUT_MS = 60000
const REDIRECT_DELAY_MS = 2500

export function StarsPurchaseSuccessScreen() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [searchParams] = useSearchParams()
  // The exact param name is set by the backend's StarsSuccessUrl; accept the
  // plausible spellings rather than 404-ing the user over a naming mismatch.
  const purchaseId =
    searchParams.get('purchase_id') ?? searchParams.get('purchaseId') ?? searchParams.get('session_id') ?? ''
  const [status, setStatus] = useState(purchaseId ? 'polling' : 'missing')

  const stoppedRef = useRef(false)
  const startedAtRef = useRef(null)

  useEffect(() => {
    if (status !== 'polling' || !purchaseId) return undefined

    stoppedRef.current = false
    startedAtRef.current = Date.now()
    let timer

    const finish = (next) => {
      stoppedRef.current = true
      setStatus(next)
    }

    const poll = async () => {
      if (stoppedRef.current) return

      try {
        const result = await starsService.getStarsPurchaseStatus(purchaseId)
        if (stoppedRef.current) return

        if (result?.Status === 'Completed') {
          queryClient.invalidateQueries({ queryKey: starsKeys.wallet() })
          queryClient.invalidateQueries({ queryKey: starsKeys.transactions() })
          finish('success')
          return
        }

        if (result?.Status === 'Failed' || result?.Status === 'Canceled') {
          finish('failed')
          return
        }

        if (Date.now() - startedAtRef.current >= POLL_TIMEOUT_MS) {
          finish('timeout')
          return
        }

        timer = setTimeout(poll, POLL_INTERVAL_MS)
      } catch (error) {
        if (stoppedRef.current) return

        // The purchase row is created before the redirect, so a 4xx here is
        // deterministic (unknown/not-ours id - e.g. a success URL carrying
        // something other than the purchase id) rather than a transient blip.
        // Bail out instead of spinning for the full timeout.
        if ([400, 403, 404].includes(error?.status)) {
          finish('timeout')
          return
        }

        if (Date.now() - startedAtRef.current >= POLL_TIMEOUT_MS) {
          finish('timeout')
          return
        }

        // Transient network hiccups shouldn't fail the whole flow - keep polling
        // until the give-up timeout above.
        timer = setTimeout(poll, POLL_INTERVAL_MS)
      }
    }

    timer = setTimeout(poll, POLL_INTERVAL_MS)

    return () => {
      stoppedRef.current = true
      clearTimeout(timer)
    }
  }, [status, purchaseId, queryClient])

  useEffect(() => {
    if (status !== 'success') return undefined
    const timer = setTimeout(() => {
      navigate(STARS_SETTINGS_PATH, { replace: true })
    }, REDIRECT_DELAY_MS)
    return () => clearTimeout(timer)
  }, [status, navigate])

  const backLink = (
    <Link to={STARS_SETTINGS_PATH} className="font-medium text-brand hover:underline">
      {t('stars.purchase.backToStars')}
    </Link>
  )

  if (status === 'polling') {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
        <Spinner size="lg" />
        <h1 className="text-lg font-semibold text-fg-heading">{t('stars.purchase.confirmingTitle')}</h1>
        <p className="text-sm text-fg-muted">{t('stars.purchase.confirmingSubtitle')}</p>
      </div>
    )
  }

  const COPY = {
    success: ['stars.purchase.successTitle', 'stars.purchase.successSubtitle'],
    failed: ['stars.purchase.failedTitle', 'stars.purchase.failedSubtitle'],
    timeout: ['stars.purchase.timeoutTitle', 'stars.purchase.timeoutSubtitle'],
    missing: ['stars.purchase.missingTitle', 'stars.purchase.missingSubtitle'],
  }
  const [titleKey, subtitleKey] = COPY[status] ?? COPY.missing

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
      <h1 className="text-lg font-semibold text-fg-heading">{t(titleKey)}</h1>
      <p className="max-w-md text-sm text-fg-muted">{t(subtitleKey)}</p>
      {backLink}
    </div>
  )
}
