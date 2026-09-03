import { ApiError } from './apiError';
import { clearTokens, getAccessToken, getRefreshToken, setTokens } from './tokenStorage';

const DEV_FALLBACK_BASE_URL = 'http://localhost:6001';
const API_PREFIX = 'Api/V1.0';

export function getApiBaseUrl() {
  const configured = import.meta.env.VITE_API_URL || DEV_FALLBACK_BASE_URL;
  return configured.replace(/\/+$/, '');
}

function buildUrl(path, query) {
  const url = new URL(`${getApiBaseUrl()}/${API_PREFIX}/${String(path).replace(/^\/+/, '')}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null) continue;
      url.searchParams.set(key, String(value));
    }
  }
  return url.toString();
}

async function parseErrorBody(response) {
  const text = await response.text().catch(() => '');
  if (!text) {
    return response.status === 429 ? 'Too Many Requests' : response.statusText || `Request failed with status ${response.status}`;
  }
  try {
    const parsed = JSON.parse(text);
    return typeof parsed?.Message === 'string' ? parsed.Message : text;
  } catch {
    return text;
  }
}

async function parseSuccessBody(response) {
  if (response.status === 204) return undefined;
  const text = await response.text().catch(() => '');
  if (!text) return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}

let inFlightRefresh = null;

async function performRefresh() {
  const accessToken = getAccessToken();
  const refreshToken = getRefreshToken();
  if (!accessToken || !refreshToken) {
    throw new ApiError('Not authenticated', 401);
  }

  const response = await fetch(buildUrl('Refresh'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ AccessToken: accessToken, RefreshToken: refreshToken }),
  });

  if (!response.ok) {
    throw new ApiError(await parseErrorBody(response), response.status);
  }

  const tokens = await parseSuccessBody(response);
  setTokens(tokens);
  return tokens;
}

function refreshTokensOnce() {
  if (!inFlightRefresh) {
    inFlightRefresh = performRefresh().finally(() => {
      inFlightRefresh = null;
    });
  }
  return inFlightRefresh;
}

export async function request(path, options = {}) {
  return performRequest(path, options, false);
}

async function performRequest(path, options, isRetry) {
  const { method = 'GET', body, query, auth = true, signal } = options;

  const headers = { Accept: 'application/json', ...options.headers };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth) {
    const token = getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  let response;
  try {
    response = await fetch(buildUrl(path, query), {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (cause) {
    throw new ApiError('Network error - please check your connection', 0, { isNetworkError: true, cause });
  }

  if (response.status === 401 && auth && !isRetry && getRefreshToken()) {
    try {
      await refreshTokensOnce();
    } catch {
      clearTokens();
      throw new ApiError('Session expired, please sign in again', 401);
    }
    return performRequest(path, options, true);
  }

  if (!response.ok) {
    const message = await parseErrorBody(response);
    if (response.status === 401 && auth) clearTokens();
    throw new ApiError(message, response.status);
  }

  return parseSuccessBody(response);
}

export async function uploadFile(path, file, options = {}) {
  return performUpload(path, file, options, false);
}

export function uploadFileWithProgress(path, file, onProgress, options = {}) {
  const { auth = true } = options;

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', buildUrl(path));

    if (auth) {
      const token = getAccessToken();
      if (token) xhr.setRequestHeader('Authorization', `Bearer ${token}`);
    }

    xhr.upload.onprogress = (event) => {
      if (!event.lengthComputable || !onProgress) return;
      onProgress(Math.round((event.loaded / event.total) * 100));
    };

    xhr.onload = async () => {
      const status = xhr.status;
      if (status >= 200 && status < 300) {
        try {
          resolve(xhr.responseText ? JSON.parse(xhr.responseText) : undefined);
        } catch {
          resolve(undefined);
        }
        return;
      }

      if (status === 401 && auth) clearTokens();

      let message = xhr.statusText || `Request failed with status ${status}`;
      try {
        const parsed = JSON.parse(xhr.responseText);
        if (typeof parsed?.Message === 'string') message = parsed.Message;
      } catch {
      }
      reject(new ApiError(message, status));
    };

    xhr.onerror = () => reject(new ApiError('Network error - please check your connection', 0, { isNetworkError: true }));

    const formData = new FormData();
    formData.append('file', file);
    xhr.send(formData);
  });
}

async function performUpload(path, file, options, isRetry) {
  const { auth = true, signal } = options;

  const headers = {};
  if (auth) {
    const token = getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const formData = new FormData();
  formData.append('file', file);

  let response;
  try {
    response = await fetch(buildUrl(path), { method: 'POST', headers, body: formData, signal });
  } catch (cause) {
    throw new ApiError('Network error - please check your connection', 0, { isNetworkError: true, cause });
  }

  if (response.status === 401 && auth && !isRetry && getRefreshToken()) {
    try {
      await refreshTokensOnce();
    } catch {
      clearTokens();
      throw new ApiError('Session expired, please sign in again', 401);
    }
    return performUpload(path, file, options, true);
  }

  if (!response.ok) {
    const message = await parseErrorBody(response);
    if (response.status === 401 && auth) clearTokens();
    throw new ApiError(message, response.status);
  }

  return parseSuccessBody(response);
}
