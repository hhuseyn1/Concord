import { Check, Copy, ShieldCheck, ShieldOff } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapTwoFactorSetupError } from '../auth/authErrors'
import {
  useDisableTwoFactorMutation,
  useEnableTwoFactorMutation,
  useRegenerateRecoveryCodesMutation,
  useStartTwoFactorSetupMutation,
  useTwoFactorStatus,
} from './settingsQueries'

function RecoveryCodesPanel({ codes, onDone }) {
  const { t } = useTranslation()
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(codes.join('\n'))
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      toast({ variant: 'warning', title: t('twoFactor.copyFailed') })
    }
  }

  return (
    <div className="flex flex-col gap-3">
      <p className="rounded-md border border-warning/40 bg-warning-bg px-3 py-2 text-sm text-warning">
        {t('twoFactor.recoveryWarning')}
      </p>
      <ul className="grid grid-cols-2 gap-1 rounded-md border border-border-default bg-surface-sidebar p-3 font-mono text-sm text-fg-default">
        {codes.map((code) => (
          <li key={code}>{code}</li>
        ))}
      </ul>
      <div className="flex gap-2">
        <Button variant="secondary" size="sm" onClick={handleCopy}>
          {copied ? <Check className="size-4" aria-hidden="true" /> : <Copy className="size-4" aria-hidden="true" />}
          {copied ? t('twoFactor.copied') : t('twoFactor.copyCodes')}
        </Button>
        <Button size="sm" onClick={onDone}>
          {t('twoFactor.savedCodes')}
        </Button>
      </div>
    </div>
  )
}

export function TwoFactorSection() {
  const { t } = useTranslation()
  const { data: status, isLoading } = useTwoFactorStatus()

  const startSetupMutation = useStartTwoFactorSetupMutation()
  const enableMutation = useEnableTwoFactorMutation()
  const disableMutation = useDisableTwoFactorMutation()
  const regenerateMutation = useRegenerateRecoveryCodesMutation()

  const [setup, setSetup] = useState(null)
  const [code, setCode] = useState('')
  const [recoveryCodes, setRecoveryCodes] = useState(null)
  const [setupError, setSetupError] = useState('')

  const [disableOpen, setDisableOpen] = useState(false)
  const [disablePassword, setDisablePassword] = useState('')
  const [disableCode, setDisableCode] = useState('')
  const [disableError, setDisableError] = useState('')

  const [regenerateOpen, setRegenerateOpen] = useState(false)
  const [regeneratePassword, setRegeneratePassword] = useState('')
  const [regenerateError, setRegenerateError] = useState('')

  function resetSetup() {
    setSetup(null)
    setCode('')
    setSetupError('')
  }

  async function handleStartSetup() {
    setSetupError('')
    try {
      setSetup(await startSetupMutation.mutateAsync())
    } catch (error) {
      toast({ variant: 'danger', title: mapTwoFactorSetupError(error) })
    }
  }

  async function handleConfirm() {
    setSetupError('')
    try {
      const result = await enableMutation.mutateAsync(code.trim())
      resetSetup()
      setRecoveryCodes(result.Codes)
      toast({ variant: 'success', title: t('twoFactor.enabled') })
    } catch (error) {
      setSetupError(mapTwoFactorSetupError(error))
    }
  }

  async function handleDisable() {
    setDisableError('')
    try {
      await disableMutation.mutateAsync({ Password: disablePassword, Code: disableCode.trim() })
      setDisableOpen(false)
      setDisablePassword('')
      setDisableCode('')
      toast({ variant: 'success', title: t('twoFactor.disabled') })
    } catch (error) {
      setDisableError(mapTwoFactorSetupError(error))
    }
  }

  async function handleRegenerate() {
    setRegenerateError('')
    try {
      const result = await regenerateMutation.mutateAsync(regeneratePassword)
      setRegenerateOpen(false)
      setRegeneratePassword('')
      setRecoveryCodes(result.Codes)
    } catch (error) {
      setRegenerateError(mapTwoFactorSetupError(error))
    }
  }

  if (isLoading) {
    return <Skeleton className="h-24 w-full max-w-md rounded-md" />
  }

  return (
    <section className="flex max-w-md flex-col gap-3">
      <div className="flex items-start gap-3">
        {status?.Enabled ? (
          <ShieldCheck className="mt-0.5 size-5 shrink-0 text-success" aria-hidden="true" />
        ) : (
          <ShieldOff className="mt-0.5 size-5 shrink-0 text-fg-muted" aria-hidden="true" />
        )}
        <div className="min-w-0 flex-1">
          <p className="text-sm font-medium text-fg-default">{t('twoFactor.title')}</p>
          <p className="text-xs text-fg-muted">
            {status?.Enabled ? t('twoFactor.enabledDescription') : t('twoFactor.disabledDescription')}
          </p>
        </div>
      </div>

      {status?.Enabled && (
        <p className="text-xs text-fg-muted">
          {t('twoFactor.remainingCodes', { count: status.RemainingRecoveryCodes })}
        </p>
      )}

      {!status?.Enabled && !setup && (
        <div>
          <Button size="sm" onClick={handleStartSetup} disabled={startSetupMutation.isPending}>
            {startSetupMutation.isPending && <Spinner size="sm" />}
            {t('twoFactor.enable')}
          </Button>
        </div>
      )}

      {setup && (
        <div className="flex flex-col gap-3 rounded-md border border-border-default p-3">
          <p className="text-sm text-fg-default">{t('twoFactor.scanInstruction')}</p>

          <img
            src={setup.QrCodeSvg}
            alt={t('twoFactor.qrAlt')}
            className="size-44 self-start rounded-md bg-white p-2"
          />

          <div>
            <p className="text-xs text-fg-muted">{t('twoFactor.manualEntry')}</p>
            <p className="font-mono text-sm break-all text-fg-default">{setup.SecretKey}</p>
          </div>

          <FormField label={t('twoFactor.confirmCode')} error={setupError} htmlFor="twofactor-confirm-code">
            <Input
              id="twofactor-confirm-code"
              value={code}
              onChange={(event) => setCode(event.target.value)}
              autoComplete="one-time-code"
              inputMode="numeric"
              placeholder="123456"
            />
          </FormField>

          <div className="flex gap-2">
            <Button size="sm" onClick={handleConfirm} disabled={enableMutation.isPending || code.trim().length === 0}>
              {enableMutation.isPending && <Spinner size="sm" />}
              {t('twoFactor.confirm')}
            </Button>
            <Button size="sm" variant="ghost" onClick={resetSetup}>
              {t('common.cancel')}
            </Button>
          </div>
        </div>
      )}

      {status?.Enabled && (
        <div className="flex gap-2">
          <Button size="sm" variant="secondary" onClick={() => setRegenerateOpen(true)}>
            {t('twoFactor.regenerate')}
          </Button>
          <Button size="sm" variant="danger" onClick={() => setDisableOpen(true)}>
            {t('twoFactor.disable')}
          </Button>
        </div>
      )}

      <Modal
        open={Boolean(recoveryCodes)}
        onOpenChange={(open) => !open && setRecoveryCodes(null)}
        title={t('twoFactor.recoveryTitle')}
        description={t('twoFactor.recoveryDescription')}
      >
        {recoveryCodes && <RecoveryCodesPanel codes={recoveryCodes} onDone={() => setRecoveryCodes(null)} />}
      </Modal>

      <Modal
        open={disableOpen}
        onOpenChange={setDisableOpen}
        title={t('twoFactor.disableTitle')}
        description={t('twoFactor.disableDescription')}
        footer={
          <>
            <Button variant="ghost" onClick={() => setDisableOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="danger" onClick={handleDisable} disabled={disableMutation.isPending}>
              {t('twoFactor.disable')}
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-3">
          <FormField label={t('twoFactor.password')} htmlFor="twofactor-disable-password">
            <PasswordInput
              id="twofactor-disable-password"
              value={disablePassword}
              onChange={(event) => setDisablePassword(event.target.value)}
              autoComplete="current-password"
            />
          </FormField>
          <FormField label={t('twoFactor.codeOrRecovery')} error={disableError} htmlFor="twofactor-disable-code">
            <Input
              id="twofactor-disable-code"
              value={disableCode}
              onChange={(event) => setDisableCode(event.target.value)}
              autoComplete="one-time-code"
              placeholder="123456"
            />
          </FormField>
        </div>
      </Modal>

      <Modal
        open={regenerateOpen}
        onOpenChange={setRegenerateOpen}
        title={t('twoFactor.regenerateTitle')}
        description={t('twoFactor.regenerateDescription')}
        footer={
          <>
            <Button variant="ghost" onClick={() => setRegenerateOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleRegenerate} disabled={regenerateMutation.isPending}>
              {t('twoFactor.regenerate')}
            </Button>
          </>
        }
      >
        <FormField label={t('twoFactor.password')} error={regenerateError} htmlFor="twofactor-regenerate-password">
          <PasswordInput
            id="twofactor-regenerate-password"
            value={regeneratePassword}
            onChange={(event) => setRegeneratePassword(event.target.value)}
            autoComplete="current-password"
          />
        </FormField>
      </Modal>
    </section>
  )
}
