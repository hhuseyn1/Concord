
const TRANSACTION_TYPES = [
  'ChatReward',
  'TransferSent',
  'TransferReceived',
  'PremiumTrialPurchase',
  'PackagePurchase',
]

const DEBIT_TYPES = new Set(['TransferSent', 'PremiumTrialPurchase'])

export function normalizeTransactionType(type) {
  if (typeof type === 'number') return TRANSACTION_TYPES[type] ?? 'Unknown'
  return TRANSACTION_TYPES.includes(type) ? type : 'Unknown'
}

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
      currency: (currency || 'usd').toUpperCase(),
    }).format(amount)
  } catch {
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

export function newIdempotencyKey() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `${Date.now()}-${Math.random().toString(36).slice(2)}-${Math.random().toString(36).slice(2)}`
}
