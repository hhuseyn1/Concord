/**
 * Presentation helpers for Stars. Everything here is derived client-side from
 * the transaction `Type`/`Amount`/`CounterpartyUsername` the API already
 * returns - there's no extra backend field behind any of it.
 */

// Declaration order of the backend `StarTransactionType` enum. Only used as a
// fallback if the API ever serializes the enum numerically instead of by name.
const TRANSACTION_TYPES = [
  'ChatReward',
  'TransferSent',
  'TransferReceived',
  'PremiumTrialPurchase',
  'PackagePurchase',
]

// Types that always move Stars *out* of the wallet.
const DEBIT_TYPES = new Set(['TransferSent', 'PremiumTrialPurchase'])

export function normalizeTransactionType(type) {
  if (typeof type === 'number') return TRANSACTION_TYPES[type] ?? 'Unknown'
  return TRANSACTION_TYPES.includes(type) ? type : 'Unknown'
}

/**
 * The amount as it should be displayed, signed. Uses the server's sign when it
 * sends one, and otherwise infers it from the transaction type, so the list is
 * correct whether the API stores debits as negative numbers or as positive
 * magnitudes.
 */
export function signedTransactionAmount(transaction) {
  const amount = Number(transaction?.Amount ?? 0)
  if (amount < 0) return amount
  return DEBIT_TYPES.has(normalizeTransactionType(transaction?.Type)) ? -amount : amount
}

export function formatStars(amount) {
  return Number(amount ?? 0).toLocaleString()
}

export function formatSignedStars(amount) {
  const value = Number(amount ?? 0)
  return `${value > 0 ? '+' : value < 0 ? '-' : ''}${Math.abs(value).toLocaleString()}`
}

export function formatPackagePrice(priceAmount, currency) {
  const amount = Number(priceAmount ?? 0)
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      // The API sends Stripe-style lowercase currency codes ("usd").
      currency: (currency || 'usd').toUpperCase(),
    }).format(amount)
  } catch {
    // Unknown/!ISO-4217 currency code - don't blow up the whole grid over it.
    return `${amount.toFixed(2)} ${(currency || '').toUpperCase()}`.trim()
  }
}

export function formatTransactionDate(value) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
}

export function formatTrialExpiry(value) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleString(undefined, { dateStyle: 'medium' })
}

/**
 * Human label for a history row, e.g. "Received from Alex" / "Premium trial".
 */
export function transactionLabel(t, transaction) {
  const type = normalizeTransactionType(transaction?.Type)
  const name = transaction?.CounterpartyUsername || t('common.unknownUser')

  switch (type) {
    case 'ChatReward':
      return t('stars.history.chatReward')
    case 'TransferReceived':
      return t('stars.history.receivedFrom', { name })
    case 'TransferSent':
      return t('stars.history.sentTo', { name })
    case 'PremiumTrialPurchase':
      return t('stars.history.premiumTrial')
    case 'PackagePurchase':
      return t('stars.history.packagePurchase')
    default:
      return t('stars.history.unknown')
  }
}

/**
 * A fresh idempotency key for one spend attempt. Reused verbatim while the user
 * retries the same attempt; regenerated once it succeeds or the form is reopened.
 */
export function newIdempotencyKey() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  // Non-secure contexts (plain http on a LAN IP) don't expose randomUUID.
  return `${Date.now()}-${Math.random().toString(36).slice(2)}-${Math.random().toString(36).slice(2)}`
}
