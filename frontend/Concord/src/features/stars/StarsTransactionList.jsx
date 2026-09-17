import { History } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { cn } from '../../lib/cn'
import {
  formatSignedStars,
  formatStars,
  formatTransactionDate,
  signedTransactionAmount,
  transactionLabel,
} from './starsFormat'
import { useStarsTransactions } from './starsQueries'

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1">
      {Array.from({ length: 4 }, (_, index) => (
        <div key={index} className="flex items-center justify-between gap-3 px-3 py-2.5">
          <Skeleton className="h-3 w-40" />
          <Skeleton className="h-3 w-12" />
        </div>
      ))}
    </div>
  )
}

export function StarsTransactionList() {
  const { t } = useTranslation()
  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage, refetch } =
    useStarsTransactions()

  const transactions = data?.pages.flatMap((page) => page.Items) ?? []

  if (isLoading) return <RowSkeletons />

  if (isError) {
    return (
      <EmptyState
        title={t('stars.history.errorTitle')}
        description={error?.message || t('common.somethingWentWrong')}
        action={
          <Button variant="secondary" size="sm" onClick={() => refetch()}>
            {t('common.tryAgain')}
          </Button>
        }
      />
    )
  }

  if (transactions.length === 0) {
    return (
      <EmptyState
        icon={History}
        title={t('stars.history.empty')}
        description={t('stars.history.emptyDescription')}
      />
    )
  }

  return (
    <div className="flex flex-col gap-2">
      <ul className="flex flex-col divide-y divide-border-subtle rounded-lg border border-border-default">
        {transactions.map((transaction) => {
          const amount = signedTransactionAmount(transaction)
          return (
            <li key={transaction.Id} className="flex items-center justify-between gap-3 px-3 py-2.5">
              <div className="min-w-0">
                <p className="truncate text-sm text-fg-default">{transactionLabel(t, transaction)}</p>
                <p className="truncate text-xs text-fg-faint">
                  {formatTransactionDate(transaction.Created)}
                  {' · '}
                  {t('stars.history.balanceAfter', { balance: formatStars(transaction.BalanceAfter) })}
                </p>
              </div>
              <p
                className={cn(
                  'shrink-0 text-sm font-semibold tabular-nums',
                  amount >= 0 ? 'text-success' : 'text-fg-default',
                )}
              >
                {t('stars.amountWithUnit', { amount: formatSignedStars(amount) })}
              </p>
            </li>
          )
        })}
      </ul>

      {hasNextPage && (
        <div className="flex justify-center">
          <Button variant="secondary" size="sm" onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
            {isFetchingNextPage && <Spinner size="sm" />}
            {t('stars.history.loadMore')}
          </Button>
        </div>
      )}
    </div>
  )
}
