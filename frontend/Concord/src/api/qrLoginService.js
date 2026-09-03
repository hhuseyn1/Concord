import { request } from './httpClient';
import { setTokens } from './tokenStorage';

export async function startQrLogin() {
  return request('QrLogin/Sessions', { method: 'POST', auth: false });
}

export async function pollQrLogin(pollingToken) {
  const result = await request('QrLogin/Sessions/Status', {
    query: { pollingToken },
    auth: false,
  });

  if (result?.Tokens?.AccessToken) {
    setTokens(result.Tokens, { rememberMe: false });
  }

  return result;
}

export async function getQrLoginRequest(userCode) {
  return request(`QrLogin/Requests/${encodeURIComponent(userCode)}`);
}

export async function approveQrLogin(userCode) {
  return request(`QrLogin/Requests/${encodeURIComponent(userCode)}/Approve`, { method: 'POST' });
}

export async function denyQrLogin(userCode) {
  return request(`QrLogin/Requests/${encodeURIComponent(userCode)}/Deny`, { method: 'POST' });
}
