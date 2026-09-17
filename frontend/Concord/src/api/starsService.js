import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

/**
 * Stars virtual-currency API (`Api/V1.0/Stars`, all endpoints authorized).
 * Mirrors `billingService.js` - the package-purchase flow is the same
 * Stripe-hosted-checkout shape as the Premium subscription one.
 */

export async function getStarsConfig() {
  return request('Stars/Config');
}

export async function getStarsWallet() {
  return request('Stars/Wallet');
}

export async function getStarsTransactions({ page, pageSize } = {}) {
  return request('Stars/Transactions', { query: buildPagingQuery(page, pageSize) });
}

/**
 * `idempotencyKey` is generated once per user attempt and reused verbatim across
 * retries of that same attempt, so a double-click or a retried request can't
 * spend twice.
 */
export async function transferStars({ recipientUserId, amount, idempotencyKey }) {
  return request('Stars/Transfer', {
    method: 'POST',
    body: { RecipientUserId: recipientUserId, Amount: amount, IdempotencyKey: idempotencyKey },
  });
}

export async function activatePremiumTrial(idempotencyKey) {
  return request('Stars/PremiumTrial/Activate', {
    method: 'POST',
    body: { IdempotencyKey: idempotencyKey },
  });
}

export async function createStarsCheckoutSession(packageId) {
  return request('Stars/Purchases/CheckoutSession', {
    method: 'POST',
    body: { PackageId: packageId },
  });
}

export async function getStarsPurchaseStatus(purchaseId) {
  return request(`Stars/Purchases/${encodeURIComponent(purchaseId)}/Status`);
}
