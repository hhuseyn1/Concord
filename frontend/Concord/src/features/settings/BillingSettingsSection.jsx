import { Mic, MessageSquare, Upload, Users } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Spinner } from '../../components/ui/Spinner'
import { cn } from '../../lib/cn'
import { useCreateCheckoutSessionMutation, useCreatePortalSessionMutation, useSubscriptionQuery } from './billingQueries'
import { mapCheckoutSessionError, mapPortalSessionError } from './settingsErrors'

const BENEFITS = [
  { icon: Mic, key: 'benefitHdVoice' },
  { icon: Users, key: 'benefitVoiceCapacity' },
  { icon: Upload, key: 'benefitUploadLimit' },
  { icon: MessageSquare, key: 'benefitMessageLength' },
]

function formatPeriodEnd(value) {
  if (!value) return ''
  return new Date(value).toLocaleString(undefined, { dateStyle: 'medium' })
}

function BenefitsList({ compact = false }) {
  const { t } = useTranslation()
  return (
    <ul className="flex flex-col gap-2">
      {BENEFITS.map(({ icon: Icon, key }) => (
        <li key={key} className="flex items-center gap-2.5">
          <Icon className={cn('shrink-0 text-brand', compact ? 'size-3.5' : 'size-4')} aria-hidden="true" />
          <span className={compact ? 'text-xs text-fg-muted' : 'text-sm text-fg-default'}>{t(`billing.${key}`)}</span>
        </li>
      ))}
    </ul>
  )
}

function SubscribeCard({ canceled }) {
  const { t } = useTranslation()
  const [formError, setFormError] = useState('')
  const createCheckoutSessionMutation = useCreateCheckoutSessionMutation()

  const handleSubscribe = async () => {
    setFormError('')
    try {
      const session = await createCheckoutSessionMutation.mutateAsync()
      // Full-page redirect: Stripe Checkout is hosted cross-origin, so this can't be a
      // client-side router navigation.
      window.location.href = session.Url
    } catch (error) {
      setFormError(mapCheckoutSessionError(error))
    }
  }

  return (
    <div className="flex max-w-md flex-col gap-4 rounded-lg border border-border-default bg-surface-sidebar p-5">
      <div>
        <h2 className="text-base font-semibold text-fg-heading">{t('billing.premiumTitle')}</h2>
        <p className="mt-1 text-sm text-fg-muted">{t('billing.premiumDescription')}</p>
      </div>

      {canceled && <p className="text-xs text-fg-muted">{t('billing.canceledNotice')}</p>}

      <div>
        <p className="mb-2 text-xs font-semibold tracking-wide text-fg-muted uppercase">
          {t('billing.benefitsTitle')}
        </p>
        <BenefitsList />
      </div>

      {formError && (
        <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}

      <div>
        <Button onClick={handleSubscribe} disabled={createCheckoutSessionMutation.isPending}>
          {createCheckoutSessionMutation.isPending && <Spinner size="sm" />}
          {t('billing.subscribe')}
        </Button>
      </div>
    </div>
  )
}

function ManageSubscriptionButton() {
  const { t } = useTranslation()
  const [formError, setFormError] = useState('')
  const createPortalSessionMutation = useCreatePortalSessionMutation()

  const handleManage = async () => {
    setFormError('')
    try {
      const session = await createPortalSessionMutation.mutateAsync()
      // Full-page redirect: the Stripe Customer Portal is hosted cross-origin, so this can't
      // be a client-side router navigation.
      window.location.href = session.Url
    } catch (error) {
      setFormError(mapPortalSessionError(error))
    }
  }

  return (
    <div>
      {formError && (
        <p role="alert" className="mb-2 rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}
      <Button variant="secondary" onClick={handleManage} disabled={createPortalSessionMutation.isPending}>
        {createPortalSessionMutation.isPending && <Spinner size="sm" />}
        {t('billing.manageSubscription')}
      </Button>
    </div>
  )
}

function ActiveCard({ subscription }) {
  const { t } = useTranslation()
  const endingSoon = subscription.CancelAtPeriodEnd
  const periodEnd = formatPeriodEnd(subscription.CurrentPeriodEnd)

  return (
    <div
      className={cn(
        'flex max-w-md flex-col gap-4 rounded-lg border p-5',
        endingSoon ? 'border-warning/30 bg-warning-bg' : 'border-success/30 bg-success-bg',
      )}
    >
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-base font-semibold text-fg-heading">{t('billing.activeTitle')}</h2>
        <Badge variant={endingSoon ? 'warning' : 'success'}>
          {endingSoon ? t('billing.endingBadge') : t('billing.activeBadge')}
        </Badge>
      </div>

      {periodEnd && (
        <p className="text-sm text-fg-default">
          {endingSoon ? t('billing.endsOn', { date: periodEnd }) : t('billing.renewsOn', { date: periodEnd })}
        </p>
      )}

      <div>
        <p className="mb-2 text-xs font-semibold tracking-wide text-fg-muted uppercase">
          {t('billing.perksReminderTitle')}
        </p>
        <BenefitsList compact />
      </div>

      <ManageSubscriptionButton />
    </div>
  )
}

function PastDueCard() {
  const { t } = useTranslation()

  return (
    <div className="flex max-w-md flex-col gap-4 rounded-lg border border-danger/30 bg-danger-bg p-5">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-base font-semibold text-fg-heading">{t('billing.pastDueTitle')}</h2>
        <Badge variant="danger">{t('billing.pastDueBadge')}</Badge>
      </div>
      <p className="text-sm text-fg-default">{t('billing.pastDueDescription')}</p>
      <ManageSubscriptionButton />
    </div>
  )
}

export function BillingSettingsSection() {
  const { t } = useTranslation()
  const { data: subscription, isLoading, isError, refetch } = useSubscriptionQuery()

  if (isLoading) {
    return (
      <div className="flex items-center gap-2 text-sm text-fg-muted">
        <Spinner size="sm" />
        {t('billing.loadingSubscription')}
      </div>
    )
  }

  if (isError) {
    return (
      <EmptyState
        title={t('billing.loadErrorTitle')}
        description={t('billing.loadErrorDescription')}
        action={
          <Button variant="secondary" size="sm" onClick={() => refetch()}>
            {t('common.tryAgain')}
          </Button>
        }
      />
    )
  }

  if (subscription?.Status === 'Active') {
    return <ActiveCard subscription={subscription} />
  }

  if (subscription?.Status === 'PastDue') {
    return <PastDueCard />
  }

  return <SubscribeCard canceled={subscription?.Status === 'Canceled'} />
}
