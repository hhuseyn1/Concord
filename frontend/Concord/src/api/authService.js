import { request } from './httpClient';
import { clearTokens, setTokens } from './tokenStorage';

export async function login({ Email, Password, RememberMe = false }) {
  const tokens = await request('Login', { method: 'POST', body: { Email, Password, RememberMe }, auth: false });

  if (tokens?.TwoFactorRequired) {
    return tokens;
  }

  setTokens(tokens, { rememberMe: RememberMe });
  return tokens;
}

export async function completeTwoFactorLogin({ TwoFactorToken, Code, rememberMe = false }) {
  const tokens = await request('Login/TwoFactor', {
    method: 'POST',
    body: { TwoFactorToken, Code },
    auth: false,
  });

  setTokens(tokens, { rememberMe });
  return tokens;
}

export async function getTwoFactorStatus() {
  return request('Me/TwoFactor');
}

export async function startTwoFactorSetup() {
  return request('Me/TwoFactor/Setup', { method: 'POST' });
}

export async function enableTwoFactor(code) {
  return request('Me/TwoFactor/Enable', { method: 'POST', body: { Code: code } });
}

export async function disableTwoFactor({ Password, Code }) {
  return request('Me/TwoFactor/Disable', { method: 'POST', body: { Password, Code } });
}

export async function regenerateRecoveryCodes(password) {
  return request('Me/TwoFactor/Recovery-Codes', { method: 'POST', body: { Password: password } });
}

export async function register({ Name, Surname, Email, Password }) {
  const tokens = await request('Register', { method: 'POST', body: { Name, Surname, Email, Password }, auth: false });
  setTokens(tokens, { rememberMe: true });
  return tokens;
}

export async function requestPasswordReset(email) {
  await request('Forgot-password', { method: 'POST', body: { Email: email }, auth: false });
}

export async function confirmPasswordReset(token, newPassword) {
  await request('Reset-password', { method: 'POST', body: { Token: token, NewPassword: newPassword }, auth: false });
}

export async function resetPassword(userId, newPassword) {
  await request(`${userId}:Reset-password`, { method: 'POST', body: { NewPassword: newPassword } });
}

export async function changePassword({ CurrentPassword, NewPassword }) {
  await request('Me:Change-password', { method: 'POST', body: { CurrentPassword, NewPassword } });
}

export function logout() {
  clearTokens();
}
