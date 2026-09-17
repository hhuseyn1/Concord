/**
 * Maps API failures to copy a person can act on. Mirrors
 * `features/settings/settingsErrors.js`.
 */

function genericMessage(t, error) {
  if (error?.isNetworkError) return t('stars.errors.network')
  if (error?.status === 429) return t('stars.errors.rateLimited')
  return error?.message || t('common.somethingWentWrong')
}

export function mapTransferError(t, error) {
  if (error?.status === 403) return t('stars.errors.notFriends')
  if (error?.status === 404) return t('stars.errors.recipientNotFound')
  if (error?.status === 409 || error?.status === 402) return t('stars.errors.insufficientBalance')
  if (error?.status === 400) return error.message || t('stars.errors.transferInvalid')
  return genericMessage(t, error)
}

export function mapPremiumTrialError(t, error) {
  if (error?.status === 409) return t('stars.errors.trialAlreadyActive')
  if (error?.status === 402) return t('stars.errors.insufficientBalance')
  if (error?.status === 400) return error.message || t('stars.errors.insufficientBalance')
  return genericMessage(t, error)
}

export function mapStarsCheckoutError(t, error) {
  if (error?.status === 404) return t('stars.errors.packageNotFound')
  return genericMessage(t, error)
}
