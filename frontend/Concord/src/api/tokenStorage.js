const STORAGE_KEY = 'concord.auth.tokens';

let activeBackend = localStorage.getItem(STORAGE_KEY) ? 'local' : 'session';

function getBackend(backend) {
  return backend === 'session' ? sessionStorage : localStorage;
}

function readStoredTokens() {
  try {
    const raw = getBackend(activeBackend).getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

let cachedTokens = readStoredTokens();

const listeners = new Set();

function notifyListeners() {
  for (const listener of listeners) listener(cachedTokens);
}

export function getTokens() {
  return cachedTokens;
}

export function getAccessToken() {
  return cachedTokens?.accessToken ?? null;
}

export function getRefreshToken() {
  return cachedTokens?.refreshToken ?? null;
}

export function isAuthenticated() {
  return Boolean(cachedTokens?.accessToken);
}

export function setTokens(tokenResponse, { rememberMe } = {}) {
  if (rememberMe !== undefined) {
    activeBackend = rememberMe ? 'local' : 'session';
  }

  cachedTokens = tokenResponse
    ? {
        accessToken: tokenResponse.AccessToken,
        refreshToken: tokenResponse.RefreshToken,
        accessTokenExpires: tokenResponse.AccessTokenExpires,
        refreshTokenExpires: tokenResponse.RefreshTokenExpires,
      }
    : null;

  localStorage.removeItem(STORAGE_KEY);
  sessionStorage.removeItem(STORAGE_KEY);

  if (cachedTokens) {
    getBackend(activeBackend).setItem(STORAGE_KEY, JSON.stringify(cachedTokens));
  }
  notifyListeners();
}

export function clearTokens() {
  setTokens(null);
}

export function subscribe(listener) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}
