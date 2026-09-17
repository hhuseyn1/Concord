import { Sparkles } from 'lucide-react'
import { useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapPremiumTrialError } from './starsErrors'
import { formatStars, formatTrialExpiry, newIdempotencyKey } from './starsFormat'
import { useActivatePremiumTrialMutation } from './starsQueries'

export function PremiumTrialCard({ config, wallet }) {
  const { t } = useTranslation()
  const activateMutation = useActivatePremiumTrialMutation()
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [formError, setFormError] = useState('')
  const idempotencyKeyRef = useRef(newIdempotencyKey())

  const cost = config?.PremiumTrialCostStars ?? 0
  const days = config?.PremiumTrialDurationDays ?? 0
  const balance = wallet?.Balance ?? 0
  const missing = Math.max(cost - balance, 0)
  const hasPremium = Boolean(wallet?.HasActivePremium)
  const trialActive = Boolean(wallet?.PremiumTrialActive)
  const expiresOn = formatTrialExpiry(wallet?.PremiumTrialExpiresAt)

  const handleActivate = async () => {
    setFormError('')
    try {
      const result = await activateMutation.mutateAsync(idempotencyKeyRef.current)
      idempotencyKeyRef.current = newIdempotencyKey()
      setConfirmOpen(false)
      toast({
        variant: 'success',
        title: t('stars.trial.successTitle'),
        description: t('stars.trial.successDescription', {
          date: formatTrialExpiry(result?.PremiumTrialExpiresAt),
        }),
      })
    } catch (error) {
      setFormError(mapPremiumTrialError(t, error))
    }
  }

  const openConfirm = () => {
    setFormError('')
    setConfirmOpen(true)
  }

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-border-default bg-surface-sidebar p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h3 className="flex items-center gap-2 text-base font-semibold text-fg-heading">
          <Sparkles className="size-4 text-brand" aria-hidden="true" />
          {t('stars.trial.title')}
        </h3>
        {trialActive && <Badge variant="success">{t('stars.trial.activeBadge')}</Badge>}
      </div>

      <p className="text-sm text-fg-muted">
        {t('stars.trial.description', { cost: formatStars(cost), days })}
      </p>

      {trialActive ? (
        <p className="text-sm text-fg-default">
          {expiresOn ? t('stars.trial.expiresOn', { date: expiresOn }) : t('stars.trial.activeBadge')}
        </p>
      ) : hasPremium ? (
        <p className="text-sm text-fg-default">{t('stars.trial.alreadyPremium')}</p>
      ) : missing > 0 ? (
        <p className="text-sm text-warning">
          {t('stars.trial.insufficient', { missing: formatStars(missing) })}
        </p>
      ) : null}

      {formError && !confirmOpen && (
        <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}

      {!trialActive && !hasPremium && (
        <div>
          <Button onClick={openConfirm} disabled={missing > 0 || activateMutation.isPending}>
            {activateMutation.isPending && <Spinner size="sm" />}
            {t('stars.trial.action')}
          </Button>
        </div>
      )}

      <Modal
        open={confirmOpen}
        onOpenChange={(next) => {
          if (activateMutation.isPending) return
          setConfirmOpen(next)
        }}
        title={t('stars.trial.confirmTitle')}
        description={t('stars.trial.confirmDescription', { cost: formatStars(cost), days })}
        footer={
          <>
            <Button variant="ghost" onClick={() => setConfirmOpen(false)} disabled={activateMutation.isPending}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleActivate} disabled={activateMutation.isPending}>
              {activateMutation.isPending && <Spinner size="sm" />}
              {t('stars.trial.confirmAction', { cost: formatStars(cost) })}
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-2">
          <p className="text-sm text-fg-muted">
            {t('stars.trial.confirmBalanceAfter', { balance: formatStars(Math.max(balance - cost, 0)) })}
          </p>
          {formError && (
            <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
              {formError}
            </p>
          )}
        </div>
      </Modal>
    </div>
  )
}
