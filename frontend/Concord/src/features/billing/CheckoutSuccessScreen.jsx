import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import * as billingService from '../../api/billingService'
import { authKeys } from '../../app/authKeys'
import { Spinner } from '../../components/ui/Spinner'

const POLL_INTERVAL_MS = 2000
const POLL_TIMEOUT_MS = 60000
const REDIRECT_DELAY_MS = 2500

export function CheckoutSuccessScreen() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [searchParams] = useSearchParams()
  const sessionId = searchParams.get('session_id') ?? ''
  const [status, setStatus] = useState(sessionId ? 'polling' : 'missing')

  const stoppedRef = useRef(false)
  const startedAtRef = useRef(null)

  useEffect(() => {
    if (status !== 'polling' || !sessionId) return undefined

    stoppedRef.current = false
    startedAtRef.current = Date.now()
    let timer

    const poll = async () => {
      if (stoppedRef.current) return

      try {
        const result = await billingService.getCheckoutSessionStatus(sessionId)

        if (stoppedRef.current) return

        if (result?.Status === 'complete') {
          stoppedRef.current = true
          queryClient.invalidateQueries({ queryKey: authKeys.me })
          setStatus('success')
          return
        }

        if (result?.Status === 'expired') {
          stoppedRef.current = true
          setStatus('expired')
          return
        }

        if (Date.now() - startedAtRef.current >= POLL_TIMEOUT_MS) {
          stoppedRef.current = true
          setStatus('timeout')
          return
        }

        timer = setTimeout(poll, POLL_INTERVAL_MS)
      } catch {
        if (stoppedRef.current) return

        if (Date.now() - startedAtRef.current >= POLL_TIMEOUT_MS) {
          stoppedRef.current = true
          setStatus('timeout')
          return
        }

        timer = setTimeout(poll, POLL_INTERVAL_MS)
      }
    }

    timer = setTimeout(poll, POLL_INTERVAL_MS)

    return () => {
      stoppedRef.current = true
      clearTimeout(timer)
    }
  }, [status, sessionId, queryClient])

  useEffect(() => {
    if (status !== 'success') return undefined
    const timer = setTimeout(() => {
      navigate('/cabinet/settings', { replace: true })
    }, REDIRECT_DELAY_MS)
    return () => clearTimeout(timer)
  }, [status, navigate])

  if (status === 'polling') {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
        <Spinner size="lg" />
        <h1 className="text-lg font-semibold text-fg-heading">{t('billing.confirmingTitle')}</h1>
        <p className="text-sm text-fg-muted">{t('billing.confirmingSubtitle')}</p>
      </div>
    )
  }

  if (status === 'success') {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
        <h1 className="text-lg font-semibold text-fg-heading">{t('billing.successTitle')}</h1>
        <p className="text-sm text-fg-muted">{t('billing.successSubtitle')}</p>
        <Link to="/cabinet/settings" className="font-medium text-brand hover:underline">
          {t('billing.backToSettings')}
        </Link>
      </div>
    )
  }

  if (status === 'expired') {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
        <h1 className="text-lg font-semibold text-fg-heading">{t('billing.expiredTitle')}</h1>
        <p className="text-sm text-fg-muted">{t('billing.expiredSubtitle')}</p>
        <Link to="/cabinet/settings" className="font-medium text-brand hover:underline">
          {t('billing.backToSettings')}
        </Link>
      </div>
    )
  }

  if (status === 'timeout') {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
        <h1 className="text-lg font-semibold text-fg-heading">{t('billing.timeoutTitle')}</h1>
        <p className="text-sm text-fg-muted">{t('billing.timeoutSubtitle')}</p>
        <Link to="/cabinet/settings" className="font-medium text-brand hover:underline">
          {t('billing.backToSettings')}
        </Link>
      </div>
    )
  }

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
      <h1 className="text-lg font-semibold text-fg-heading">{t('billing.missingSessionTitle')}</h1>
      <p className="text-sm text-fg-muted">{t('billing.missingSessionSubtitle')}</p>
      <Link to="/cabinet/settings" className="font-medium text-brand hover:underline">
        {t('billing.backToSettings')}
      </Link>
    </div>
  )
}
