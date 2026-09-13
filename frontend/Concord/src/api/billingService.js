import { request } from './httpClient';

export async function createCheckoutSession() {
  return request('Billing/CheckoutSession', { method: 'POST' });
}

export async function getCheckoutSessionStatus(sessionId) {
  return request(`Billing/CheckoutSession/${encodeURIComponent(sessionId)}/Status`);
}

export async function getSubscription() {
  return request('Billing/Subscription');
}

export async function createPortalSession() {
  return request('Billing/PortalSession', { method: 'POST' });
}
