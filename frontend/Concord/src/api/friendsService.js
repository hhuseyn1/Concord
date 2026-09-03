import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function sendFriendRequest(targetUserId) {
  return request(`Friends/Requests/${targetUserId}`, { method: 'POST' });
}

export async function acceptFriendRequest(requestId) {
  await request(`Friends/Requests/${requestId}:Accept`, { method: 'POST' });
}

export async function declineFriendRequest(requestId) {
  await request(`Friends/Requests/${requestId}:Decline`, { method: 'POST' });
}

export async function cancelFriendRequest(requestId) {
  await request(`Friends/Requests/${requestId}`, { method: 'DELETE' });
}

export async function getIncomingFriendRequests() {
  return request('Friends/Requests/Incoming');
}

export async function getOutgoingFriendRequests() {
  return request('Friends/Requests/Outgoing');
}

export async function getFriends({ page, pageSize } = {}) {
  return request('Friends', { query: buildPagingQuery(page, pageSize) });
}

export async function blockUser(targetUserId) {
  await request(`Friends/Blocks/${targetUserId}`, { method: 'POST' });
}

export async function unblockUser(targetUserId) {
  await request(`Friends/Blocks/${targetUserId}`, { method: 'DELETE' });
}

export async function getBlockedUsers({ page, pageSize } = {}) {
  return request('Friends/Blocks', { query: buildPagingQuery(page, pageSize) });
}
