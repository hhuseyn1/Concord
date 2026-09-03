import { request } from './httpClient';

export async function getMe() {
  return request('Users/Me');
}

export async function updateMe({ Name, Surname, Username, AvatarUrl = null }) {
  return request('Users/Me', { method: 'PUT', body: { Name, Surname, Username, AvatarUrl } });
}

export async function getUserById(userId) {
  return request(`Users/${userId}`);
}

export async function searchUsers(query) {
  return request('Users/Search', { query: { query } });
}

export async function updateMyPreferences({ Locale, NotificationsMuted, NotificationsSoundEnabled }) {
  return request('Users/Me/Preferences', {
    method: 'PUT',
    body: { Locale, NotificationsMuted, NotificationsSoundEnabled },
  });
}

export async function updateMyPrivacy({ FriendRequestPrivacy, DirectMessagePrivacy, ActivityVisibility, ReadReceiptsEnabled }) {
  return request('Users/Me/Privacy', {
    method: 'PUT',
    body: { FriendRequestPrivacy, DirectMessagePrivacy, ActivityVisibility, ReadReceiptsEnabled },
  });
}

export async function updateMyCustomStatus({ Emoji, Text, ExpiryPreset }) {
  return request('Users/Me/CustomStatus', { method: 'PUT', body: { Emoji, Text, ExpiryPreset } });
}
