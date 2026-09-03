import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function getNotifications({ page, pageSize } = {}) {
  return request('Notifications', { query: buildPagingQuery(page, pageSize) });
}

export async function markNotificationRead(notificationId) {
  await request(`Notifications/${notificationId}:Read`, { method: 'POST' });
}

export async function markAllNotificationsRead() {
  await request('Notifications/Read', { method: 'POST' });
}
