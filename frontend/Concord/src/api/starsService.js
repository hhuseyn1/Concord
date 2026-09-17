import { request } from './httpClient';
import { buildPagingQuery } from './pagination';


export async function getStarsConfig() {
  return request('Stars/Config');
}

export async function getStarsWallet() {
  return request('Stars/Wallet');
}

export async function getStarsTransactions({ page, pageSize } = {}) {
  return request('Stars/Transactions', { query: buildPagingQuery(page, pageSize) });
}

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
