import { Search, Star, Users } from 'lucide-react'
import { useMemo, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { useFriendsList } from '../friends/friendsQueries'
import { mapTransferError } from './starsErrors'
import { formatStars, newIdempotencyKey } from './starsFormat'
import { useTransferStarsMutation } from './starsQueries'

const CONFIRM_ABSOLUTE_THRESHOLD = 100
const CONFIRM_BALANCE_FRACTION = 0.5

function friendName(user) {
  return user?.Username || [user?.Name, user?.Surname].filter(Boolean).join(' ') || ''
}

function RecipientPicker({ friends, isLoading, isError, query, selectedId, onSelect, onRetry }) {
  const { t } = useTranslation()

  if (isLoading) {
    return (
      <div className="flex flex-col gap-1 p-2">
        {Array.from({ length: 3 }, (_, index) => (
          <div key={index} className="flex items-center gap-3 px-1 py-1.5">
            <Skeleton className="size-8 rounded-full" />
            <Skeleton className="h-3 w-28" />
          </div>
        ))}
      </div>
    )
  }

  if (isError) {
    return (
      <EmptyState
        compact
        title={t('stars.send.friendsErrorTitle')}
        description={t('stars.send.friendsErrorDescription')}
        action={
          <Button variant="secondary" size="sm" className="mt-2" onClick={onRetry}>
            {t('common.tryAgain')}
          </Button>
        }
      />
    )
  }

  if (friends.length === 0) {
    return (
      <EmptyState
        compact
        title={query ? t('stars.send.noMatches', { query }) : t('stars.send.noFriends')}
        description={query ? undefined : t('stars.send.noFriendsDescription')}
      />
    )
  }

  return (
    <div className="flex max-h-48 flex-col gap-0.5 overflow-y-auto p-1" role="none">
      {friends.map((user) => {
        const name = friendName(user) || t('common.unknownUser')
        return (
          <label
            key={user.Id}
            className="flex cursor-pointer items-center gap-3 rounded-md px-2 py-1.5 transition-colors duration-150 hover:bg-fg-default/5 has-[:checked]:bg-brand-bg has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brand"
          >
            <input
              type="radio"
              name="stars-recipient"
              value={user.Id}
              checked={selectedId === user.Id}
              onChange={() => onSelect(user)}
              className="sr-only"
            />
            <Avatar src={user?.AvatarUrl ?? undefined} name={name} size="sm" />
            <span className="min-w-0 flex-1 truncate text-sm text-fg-default">{name}</span>
            {selectedId === user.Id && (
              <Star className="size-4 shrink-0 fill-current text-brand" aria-hidden="true" />
            )}
          </label>
        )
      })}
    </div>
  )
}

export function SendStarsModal({ open, onOpenChange, balance = 0 }) {
  const { t } = useTranslation()
  const { user: currentUser } = useAuth()
  const transferMutation = useTransferStarsMutation()
  const {
    data,
    isLoading: friendsLoading,
    isError: friendsError,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    refetch: refetchFriends,
  } = useFriendsList()

  const [query, setQuery] = useState('')
  const [recipient, setRecipient] = useState(null)
  const [amount, setAmount] = useState('')
  const [formError, setFormError] = useState('')
  const [confirming, setConfirming] = useState(false)

  const idempotencyKeyRef = useRef(newIdempotencyKey())

  const friends = useMemo(() => {
    const items = data?.pages.flatMap((page) => page.Items) ?? []
    const normalized = query.trim().toLowerCase()
    const withoutSelf = items.filter((item) => item.Id !== currentUser?.Id)
    if (!normalized) return withoutSelf
    return withoutSelf.filter((item) => friendName(item).toLowerCase().includes(normalized))
  }, [data, query, currentUser?.Id])

  const parsedAmount = Number(amount)
  const amountIsValid =
    amount.trim() !== '' && Number.isInteger(parsedAmount) && parsedAmount > 0 && parsedAmount <= balance

  const validate = () => {
    if (!recipient) return t('stars.send.errorNoRecipient')
    if (recipient.Id === currentUser?.Id) return t('stars.send.errorSelf')
    if (amount.trim() === '') return t('stars.send.errorAmountRequired')
    if (!Number.isInteger(parsedAmount) || parsedAmount <= 0) return t('stars.send.errorAmountPositive')
    if (parsedAmount > balance) return t('stars.send.errorAmountTooLarge', { balance: formatStars(balance) })
    return ''
  }

  const needsConfirmation =
    parsedAmount >= CONFIRM_ABSOLUTE_THRESHOLD ||
    (balance > 0 && parsedAmount >= balance * CONFIRM_BALANCE_FRACTION)

  const send = async () => {
    const error = validate()
    if (error) {
      setFormError(error)
      setConfirming(false)
      return
    }

    setFormError('')
    try {
      await transferMutation.mutateAsync({
        recipientUserId: recipient.Id,
        amount: parsedAmount,
        idempotencyKey: idempotencyKeyRef.current,
      })
      toast({
        variant: 'success',
        title: t('stars.send.successTitle'),
        description: t('stars.send.successDescription', {
          amount: formatStars(parsedAmount),
          name: friendName(recipient) || t('common.unknownUser'),
        }),
      })
      idempotencyKeyRef.current = newIdempotencyKey()
      onOpenChange(false)
    } catch (sendError) {
      setConfirming(false)
      setFormError(mapTransferError(t, sendError))
    }
  }

  const handleSubmit = () => {
    const error = validate()
    if (error) {
      setFormError(error)
      return
    }
    if (needsConfirmation) {
      setFormError('')
      setConfirming(true)
      return
    }
    send()
  }

  const recipientName = friendName(recipient) || t('common.unknownUser')
  const isPending = transferMutation.isPending

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={confirming ? t('stars.send.confirmTitle') : t('stars.send.title')}
      description={confirming ? undefined : t('stars.send.description')}
      footer={
        confirming ? (
          <>
            <Button variant="ghost" onClick={() => setConfirming(false)} disabled={isPending}>
              {t('stars.send.back')}
            </Button>
            <Button onClick={send} disabled={isPending}>
              {isPending && <Spinner size="sm" />}
              {t('stars.send.confirmAction', { amount: formatStars(parsedAmount) })}
            </Button>
          </>
        ) : (
          <>
            <Button variant="ghost" onClick={() => onOpenChange(false)} disabled={isPending}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleSubmit} disabled={isPending || !recipient || !amountIsValid}>
              {isPending && <Spinner size="sm" />}
              {t('stars.send.submit')}
            </Button>
          </>
        )
      }
    >
      {confirming ? (
        <div className="flex flex-col gap-3">
          <p className="text-sm text-fg-default">
            {t('stars.send.confirmDescription', {
              amount: formatStars(parsedAmount),
              name: recipientName,
            })}
          </p>
          <p className="text-sm text-fg-muted">
            {t('stars.send.confirmBalanceAfter', { balance: formatStars(balance - parsedAmount) })}
          </p>
          {formError && (
            <p
              role="alert"
              className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger"
            >
              {formError}
            </p>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <p className="text-sm font-medium text-fg-default" id="stars-recipient-label">
              {t('stars.send.recipientLabel')}
            </p>
            <div className="rounded-md border border-border-default bg-surface-sidebar">
              <div className="relative border-b border-border-subtle p-2">
                <Search
                  className="pointer-events-none absolute top-1/2 left-4 size-4 -translate-y-1/2 text-fg-faint"
                  aria-hidden="true"
                />
                <Input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder={t('stars.send.searchPlaceholder')}
                  aria-label={t('stars.send.searchPlaceholder')}
                  className="pl-8"
                />
              </div>
              <fieldset aria-labelledby="stars-recipient-label">
                <RecipientPicker
                  friends={friends}
                  isLoading={friendsLoading}
                  isError={friendsError}
                  query={query.trim()}
                  selectedId={recipient?.Id ?? null}
                  onSelect={(user) => {
                    setRecipient(user)
                    setFormError('')
                  }}
                  onRetry={() => refetchFriends()}
                />
              </fieldset>
              {hasNextPage && !query.trim() && (
                <div className="border-t border-border-subtle p-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="w-full"
                    onClick={() => fetchNextPage()}
                    disabled={isFetchingNextPage}
                  >
                    {isFetchingNextPage && <Spinner size="sm" />}
                    {t('stars.send.loadMoreFriends')}
                  </Button>
                </div>
              )}
            </div>
          </div>

          <FormField
            label={t('stars.send.amountLabel')}
            hint={t('stars.send.amountHint', { balance: formatStars(balance) })}
            error={formError || undefined}
          >
            <Input
              type="number"
              inputMode="numeric"
              min={1}
              max={balance || undefined}
              step={1}
              value={amount}
              onChange={(event) => {
                setAmount(event.target.value)
                setFormError('')
              }}
              placeholder="0"
            />
          </FormField>

          {balance <= 0 && (
            <p className="flex items-center gap-2 text-xs text-fg-muted">
              <Users className="size-3.5 shrink-0" aria-hidden="true" />
              {t('stars.send.noBalance')}
            </p>
          )}
        </div>
      )}
    </Modal>
  )
}
