import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import 'api_config.dart';
import 'api_exception.dart';
import 'models/token_response.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required this._tokenStorage,
    http.Client? httpClient,
    String? baseUrl,
    this.onSessionExpired,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.restBaseUrl;

  final http.Client _http;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  final void Function()? onSessionExpired;

  Future<void>? _refreshInFlight;

  /// Bounded timeout applied to every underlying HTTP call so a bad network
  /// (or a request that never gets a response) surfaces as a distinguishable
  /// [ApiException] instead of hanging the UI indefinitely.
  static const Duration _requestTimeout = Duration(seconds: 15);

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse('$_baseUrl/$normalizedPath');
    if (query == null || query.isEmpty) return base;
    final stringQuery = <String, String>{};
    query.forEach((key, value) {
      if (value != null) stringQuery[key] = value.toString();
    });
    return base.replace(queryParameters: {...base.queryParameters, ...stringQuery});
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) {
    return _send('POST', path, query: query, jsonBody: body, auth: auth);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) {
    return _send('PUT', path, query: query, jsonBody: body, auth: auth);
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) {
    return _send('DELETE', path, query: query, jsonBody: body, auth: auth);
  }

  Future<dynamic> postMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(path, null);
    final request = http.MultipartRequest('POST', uri);
    final token = await _tokenStorage.readAccessToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType == null ? null : _parseMediaType(contentType),
      ),
    );

    http.Response response;
    try {
      final streamedResponse = await _http.send(request).timeout(_requestTimeout);
      response = await http.Response.fromStream(streamedResponse).timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(ApiException.timeoutStatusCode, 'The request timed out.');
    } catch (e) {
      throw const ApiException(ApiException.networkErrorStatusCode, 'A network error occurred.');
    }

    if (response.statusCode == 401 && !isRetry) {
      final refreshed = await _ensureRefreshed();
      if (refreshed) {
        return postMultipart(
          path,
          bytes: bytes,
          filename: filename,
          contentType: contentType,
          isRetry: true,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeSuccess(response);
    }
    throw _errorFromResponse(response);
  }

  http_parser.MediaType? _parseMediaType(String contentType) {
    final parts = contentType.split('/');
    if (parts.length != 2) return null;
    return http_parser.MediaType(parts[0], parts[1]);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? jsonBody,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(path, query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonBody != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final encodedBody = jsonBody == null ? null : jsonEncode(jsonBody);

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers).timeout(_requestTimeout);
          break;
        case 'POST':
          response = await _http.post(uri, headers: headers, body: encodedBody).timeout(_requestTimeout);
          break;
        case 'PUT':
          response = await _http.put(uri, headers: headers, body: encodedBody).timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await _http.delete(uri, headers: headers, body: encodedBody).timeout(_requestTimeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const ApiException(ApiException.timeoutStatusCode, 'The request timed out.');
    } on ArgumentError {
      rethrow;
    } catch (e) {
      throw const ApiException(ApiException.networkErrorStatusCode, 'A network error occurred.');
    }

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _ensureRefreshed();
      if (refreshed) {
        return _send(method, path, query: query, jsonBody: jsonBody, auth: auth, isRetry: true);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeSuccess(response);
    }
    throw _errorFromResponse(response);
  }

  Future<bool> _ensureRefreshed() {
    _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight!.then((_) => true, onError: (_) => false);
  }

  Future<void> _doRefresh() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (accessToken == null || refreshToken == null) {
      await _tokenStorage.clear();
      onSessionExpired?.call();
      throw const ApiException(401, 'No refresh token available.');
    }

    final uri = _buildUri('/Refresh', null);
    http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'AccessToken': accessToken, 'RefreshToken': refreshToken}),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(ApiException.timeoutStatusCode, 'The request timed out during refresh.');
    } catch (e) {
      throw const ApiException(ApiException.networkErrorStatusCode, 'A network error occurred during refresh.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _decodeSuccess(response) as Map<String, dynamic>;
      await _tokenStorage.saveTokens(TokenResponse.fromJson(data));
      return;
    }

    await _tokenStorage.clear();
    onSessionExpired?.call();
    throw _errorFromResponse(response);
  }

  dynamic _decodeSuccess(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  ApiException _errorFromResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      final message = response.statusCode == 429 ? 'Too Many Requests' : 'Request failed';
      return ApiException(response.statusCode, message);
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['Message'] is String) {
        return ApiException(response.statusCode, decoded['Message'] as String);
      }
    } catch (_) {
    }
    return ApiException(response.statusCode, 'Request failed');
  }
}
