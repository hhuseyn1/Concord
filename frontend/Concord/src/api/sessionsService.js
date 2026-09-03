import { request } from './httpClient';

export async function getSessions() {
  return request('Sessions');
}

export async function revokeSession(sessionId) {
  await request(`Sessions/${sessionId}`, { method: 'DELETE' });
}

export async function revokeCurrentSession() {
  await request('Sessions/Current', { method: 'DELETE' });
}

export async function revokeOtherSessions() {
  await request('Sessions/Others', { method: 'DELETE' });
}
