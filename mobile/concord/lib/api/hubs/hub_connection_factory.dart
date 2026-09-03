import 'package:signalr_netcore/signalr_client.dart';

import '../api_config.dart';
import '../token_storage.dart';

HubConnection buildHubConnection({
  required String hubPath,
  required TokenStorage tokenStorage,
  String? baseUrl,
}) {
  final url = '${baseUrl ?? ApiConfig.hubsBaseUrl}$hubPath';
  final options = HttpConnectionOptions(
    accessTokenFactory: () async => (await tokenStorage.readAccessToken()) ?? '',
    logMessageContent: false,
  );
  return HubConnectionBuilder()
      .withUrl(url, options: options)
      .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 20000])
      .build();
}
