import { Send, Star } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { PremiumTrialCard } from './PremiumTrialCard'
import { SendStarsModal } from './SendStarsModal'
import { StarsPackagesGrid } from './StarsPackagesGrid'
import { StarsTransactionList } from './StarsTransactionList'
import { formatStars } from './starsFormat'
import { useStarsConfig, useStarsWallet } from './starsQueries'

function BalanceCard({ wallet, config, onSend }) {
  const { t } = useTranslation()
  const balance = wallet?.Balance ?? 0

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-border-default bg-surface-sidebar p-5 sm:flex-row sm:items-center sm:justify-between">
      <div className="min-w-0">
        <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">
          {t('stars.balanceLabel')}
        </p>
        <p className="mt-1 flex items-center gap-2">
          <Star className="size-7 shrink-0 fill-current text-warning" aria-hidden="true" />
          <span className="text-2xl font-bold text-fg-heading tabular-nums">{formatStars(balance)}</span>
          <span className="text-sm text-fg-muted">{t('stars.unit')}</span>
        </p>
        {config && (
          <p className="mt-2 max-w-sm text-xs text-fg-muted">
            {t('stars.earnHint', {
              amount: formatStars(config.ChatRewardAmount),
              cap: formatStars(config.ChatRewardDailyCap),
              seconds: config.ChatRewardCooldownSeconds,
            })}
          </p>
        )}
      </div>
      <Button className="shrink-0" onClick={onSend} disabled={balance <= 0}>
        <Send className="size-4" aria-hidden="true" />
        {t('stars.sendStars')}
      </Button>
    </div>
  )
}

function LoadingState() {
  return (
    <div className="flex flex-col gap-4">
      <Skeleton className="h-28 w-full rounded-lg" />
      <Skeleton className="h-36 w-full rounded-lg" />
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: 4 }, (_, index) => (
          <Skeleton key={index} className="h-32 w-full rounded-lg" />
        ))}
      </div>
    </div>
  )
}

export function StarsSettingsSection() {
  const { t } = useTranslation()
  const configQuery = useStarsConfig()
  const walletQuery = useStarsWallet()
  const [sendOpen, setSendOpen] = useState(false)
  const [sendAttempt, setSendAttempt] = useState(0)

  const openSendModal = () => {
    setSendAttempt((attempt) => attempt + 1)
    setSendOpen(true)
  }

  if (configQuery.isLoading || walletQuery.isLoading) {
    return <LoadingState />
  }

  if (configQuery.isError || walletQuery.isError) {
    return (
      <EmptyState
        icon={Star}
        title={t('stars.loadErrorTitle')}
        description={t('stars.loadErrorDescription')}
        action={
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              configQuery.refetch()
              walletQuery.refetch()
            }}
          >
            {t('common.tryAgain')}
          </Button>
        }
      />
    )
  }

  const config = configQuery.data
  const wallet = walletQuery.data

  return (
    <div className="flex flex-col gap-8">
      <BalanceCard wallet={wallet} config={config} onSend={openSendModal} />

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('stars.trial.sectionTitle')}</h2>
        <PremiumTrialCard config={config} wallet={wallet} />
      </section>

      <section className="flex flex-col gap-3">
        <div>
          <h2 className="text-sm font-semibold text-fg-heading">{t('stars.packages.title')}</h2>
          <p className="text-xs text-fg-muted">{t('stars.packages.description')}</p>
        </div>
        <StarsPackagesGrid packages={config?.Packages} />
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-fg-heading">{t('stars.history.title')}</h2>
        <StarsTransactionList />
      </section>

      <SendStarsModal
        key={sendAttempt}
        open={sendOpen}
        onOpenChange={setSendOpen}
        balance={wallet?.Balance ?? 0}
      />
    </div>
  )
}
