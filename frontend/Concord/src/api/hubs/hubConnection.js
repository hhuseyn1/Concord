import * as signalR from '@microsoft/signalr';
import { getApiBaseUrl } from '../httpClient';
import { getAccessToken } from '../tokenStorage';
import { reportReconnected, reportReconnecting, reportSettled } from './connectionStatusStore';

let connectionCounter = 0;

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

  return connection;
}
