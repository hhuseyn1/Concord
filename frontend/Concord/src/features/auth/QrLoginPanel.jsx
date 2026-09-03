import { QrCode, RefreshCw } from 'lucide-react'
import { useCallback, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import * as qrLoginService from '../../api/qrLoginService'
import { Button } from '../../components/ui/Button'
import { Spinner } from '../../components/ui/Spinner'

const POLL_INTERVAL_MS = 2000

export function QrLoginPanel({ onAuthenticated }) {
  const { t } = useTranslation()
  const [session, setSession] = useState(null)
  const [status, setStatus] = useState('idle')
  const [error, setError] = useState('')

  const stoppedRef = useRef(false)

  const start = useCallback(async () => {
    setError('')
    setStatus('starting')
    stoppedRef.current = false
    try {
      const started = await qrLoginService.startQrLogin()
      setSession(started)
      setStatus('waiting')
    } catch {
      setStatus('idle')
      setError(t('qrLogin.startFailed'))
    }
  }, [t])

  useEffect(() => {
    if (status !== 'waiting' || !session?.PollingToken) return undefined

    let timer

    const poll = async () => {
      if (stoppedRef.current) return

      try {
        const result = await qrLoginService.pollQrLogin(session.PollingToken)

        if (stoppedRef.current) return

        if (result?.Tokens?.AccessToken) {
          stoppedRef.current = true
          setStatus('done')
          onAuthenticated()
          return
        }

        if (result?.Expired) {
          stoppedRef.current = true
          setStatus('expired')
          return
        }

        if (result?.Status === 'Denied') {
          stoppedRef.current = true
          setStatus('denied')
          return
        }

        timer = setTimeout(poll, POLL_INTERVAL_MS)
      } catch {
        if (!stoppedRef.current) {
          timer = setTimeout(poll, POLL_INTERVAL_MS)
        }
      }
    }

    timer = setTimeout(poll, POLL_INTERVAL_MS)

    return () => {
      stoppedRef.current = true
      clearTimeout(timer)
    }
  }, [status, session, onAuthenticated])

  if (status === 'idle' || status === 'starting') {
    return (
      <div className="flex flex-col items-center gap-2 text-center">
        <Button variant="secondary" size="sm" onClick={start} disabled={status === 'starting'}>
          {status === 'starting' ? <Spinner size="sm" /> : <QrCode className="size-4" aria-hidden="true" />}
          {t('qrLogin.showCode')}
        </Button>
        <p className="text-xs text-fg-muted">{t('qrLogin.hint')}</p>
        {error && (
          <p role="alert" className="text-xs text-danger">
            {error}
          </p>
        )}
      </div>
    )
  }

  if (status === 'expired' || status === 'denied') {
    return (
      <div className="flex flex-col items-center gap-2 text-center">
        <p className="text-sm text-fg-muted">{status === 'denied' ? t('qrLogin.denied') : t('qrLogin.expired')}</p>
        <Button variant="secondary" size="sm" onClick={start}>
          <RefreshCw className="size-4" aria-hidden="true" />
          {t('qrLogin.newCode')}
        </Button>
      </div>
    )
  }

  return (
    <div className="flex flex-col items-center gap-3 text-center">
      <img
        src={session.QrCodeSvg}
        alt={t('qrLogin.qrAlt')}
        className="size-40 rounded-md bg-white p-2"
      />
      <div>
        <p className="text-xs text-fg-muted">{t('qrLogin.orEnterCode')}</p>
        <p className="font-mono text-lg tracking-widest text-fg-default">{session.UserCode}</p>
      </div>
      <p className="flex items-center gap-2 text-xs text-fg-muted">
        <Spinner size="sm" />
        {t('qrLogin.waiting')}
      </p>
    </div>
  )
}
