import * as signalR from '@microsoft/signalr';
import { getApiBaseUrl } from '../httpClient';
import { getAccessToken } from '../tokenStorage';
import { reportReconnected, reportReconnecting, reportSettled } from './connectionStatusStore';

let connectionCounter = 0;

// withAutomaticReconnect only covers reconnection after a connection has
// succeeded at least once. A transient failure on the very first handshake
// (cold start, brief network hiccup, token not yet available) is otherwise
// fatal, so the initial start() is retried here with bounded exponential
// backoff + jitter. This does NOT duplicate withAutomaticReconnect: once a
// connection succeeds, all reconnection after that is handled by SignalR
// itself, untouched by this wrapper.
const START_MAX_ATTEMPTS = 5;
const START_BASE_DELAY_MS = 1000;
const START_MAX_DELAY_MS = 8000;

function startRetryDelayMs(attempt) {
  const exponential = Math.min(START_BASE_DELAY_MS * 2 ** attempt, START_MAX_DELAY_MS);
  return Math.round(exponential * (0.75 + Math.random() * 0.5)); // +/-25% jitter
}

export function createHubConnection(hubPath) {
  const connection = new signalR.HubConnectionBuilder()
    .withUrl(`${getApiBaseUrl()}${hubPath}`, {
      accessTokenFactory: () => getAccessToken() ?? '',
      withCredentials: false,
    })
    .withAutomaticReconnect()
    .configureLogging(signalR.LogLevel.Warning)
    .build();

  const connectionId = `${hubPath}:${++connectionCounter}`;
  connection.onreconnecting(() => reportReconnecting(connectionId));
  connection.onreconnected(() => reportReconnected(connectionId));
  connection.onclose(() => reportSettled(connectionId));

  const originalStart = connection.start.bind(connection);
  const originalStop = connection.stop.bind(connection);

  let cancelled = false;
  let pendingTimer = null;
  let inFlightStart = null;

  const wait = (ms) =>
    new Promise((resolve, reject) => {
      pendingTimer = setTimeout(() => {
        pendingTimer = null;
        if (cancelled) reject(new Error(`Hub connection start cancelled (${hubPath})`));
        else resolve();
      }, ms);
    });

  const attemptStart = async (attempt = 0) => {
    try {
      await originalStart();
    } catch (error) {
      if (cancelled || attempt >= START_MAX_ATTEMPTS - 1) throw error;
      await wait(startRetryDelayMs(attempt));
      await attemptStart(attempt + 1);
    }
  };

  // Guard against overlapping start() calls (e.g. a caller invoking start()
  // again before the previous attempt/retry chain has settled) by handing
  // back the same in-flight promise instead of racing a second originalStart().
  connection.start = () => {
    if (inFlightStart) return inFlightStart;
    cancelled = false;
    inFlightStart = attemptStart().finally(() => {
      inFlightStart = null;
    });
    return inFlightStart;
  };

  connection.stop = () => {
    cancelled = true;
    if (pendingTimer) {
      clearTimeout(pendingTimer);
      pendingTimer = null;
    }
    return originalStop();
  };

  return connection;
}
