import { Check, MonitorSmartphone, X } from 'lucide-react'
import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate, useSearchParams } from 'react-router-dom'
import * as qrLoginService from '../../api/qrLoginService'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { AuthLayout } from './AuthLayout'
import { mapQrLoginApprovalError } from './authErrors'

export function LinkDeviceScreen() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  const [code, setCode] = useState(searchParams.get('code') ?? '')
  const [request, setRequest] = useState(null)
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const codeFromUrl = searchParams.get('code')

  const lookup = useCallback(async (value) => {
    const trimmed = value?.trim()
    if (!trimmed) return

    setError('')
    setLoading(true)
    try {
      setRequest(await qrLoginService.getQrLoginRequest(trimmed))
    } catch (lookupError) {
      setRequest(null)
      setError(mapQrLoginApprovalError(lookupError))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!codeFromUrl) return undefined

    let cancelled = false

    void (async () => {
      await lookup(codeFromUrl)
      if (cancelled) setRequest(null)
    })()

    return () => {
      cancelled = true
    }
  }, [codeFromUrl, lookup])

  async function handleApprove() {
    setSubmitting(true)
    setError('')
    try {
      await qrLoginService.approveQrLogin(request.UserCode)
      toast({ variant: 'success', title: t('qrLogin.approved') })
      navigate('/cabinet', { replace: true })
    } catch (approveError) {
      setError(mapQrLoginApprovalError(approveError))
    } finally {
      setSubmitting(false)
    }
  }

  async function handleDeny() {
    setSubmitting(true)
    setError('')
    try {
      await qrLoginService.denyQrLogin(request.UserCode)
      toast({ variant: 'info', title: t('qrLogin.deniedConfirmation') })
      navigate('/cabinet', { replace: true })
    } catch (denyError) {
      setError(mapQrLoginApprovalError(denyError))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AuthLayout title={t('qrLogin.approveTitle')} subtitle={t('qrLogin.approveSubtitle')}>
      <div className="flex flex-col gap-4">
        {!request && (
          <>
            <FormField label={t('qrLogin.codeLabel')} error={error} htmlFor="link-code">
              <Input
                id="link-code"
                value={code}
                onChange={(event) => setCode(event.target.value)}
                placeholder="ABCD1234"
                autoComplete="off"
                autoFocus
              />
            </FormField>
            <Button onClick={() => lookup(code)} disabled={loading || code.trim().length === 0}>
              {loading && <Spinner size="sm" />}
              {t('qrLogin.continue')}
            </Button>
          </>
        )}

        {loading && request === null && codeFromUrl && <Skeleton className="h-32 w-full rounded-md" />}

        {request && (
          <>
            <div className="flex items-start gap-3 rounded-md border border-border-default bg-surface-sidebar p-3">
              <MonitorSmartphone className="mt-0.5 size-5 shrink-0 text-fg-muted" aria-hidden="true" />
              <div className="min-w-0 text-sm">
                <p className="font-medium text-fg-default">{request.DeviceLabel || t('qrLogin.unknownDevice')}</p>
                <p className="text-xs text-fg-muted">
                  {[request.Browser, request.OS].filter(Boolean).join(' · ') || t('qrLogin.unknownDevice')}
                </p>
                {request.IpAddress && <p className="text-xs text-fg-muted">{request.IpAddress}</p>}
              </div>
            </div>

            <p className="rounded-md border border-warning/40 bg-warning-bg px-3 py-2 text-sm text-warning">
              {t('qrLogin.approveWarning')}
            </p>

            {error && (
              <p role="alert" className="text-sm text-danger">
                {error}
              </p>
            )}

            <div className="flex gap-2">
              <Button onClick={handleApprove} disabled={submitting} className="flex-1">
                {submitting ? <Spinner size="sm" /> : <Check className="size-4" aria-hidden="true" />}
                {t('qrLogin.approve')}
              </Button>
              <Button variant="danger" onClick={handleDeny} disabled={submitting} className="flex-1">
                <X className="size-4" aria-hidden="true" />
                {t('qrLogin.deny')}
              </Button>
            </div>
          </>
        )}
      </div>
    </AuthLayout>
  )
}
