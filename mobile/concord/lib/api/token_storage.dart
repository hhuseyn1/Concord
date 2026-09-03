import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/token_response.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'concord.accessToken';
  static const _refreshTokenKey = 'concord.refreshToken';
  static const _accessTokenExpiresKey = 'concord.accessTokenExpires';
  static const _refreshTokenExpiresKey = 'concord.refreshTokenExpires';

  Future<void> saveTokens(TokenResponse tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _storage.write(
        key: _accessTokenExpiresKey,
        value: tokens.accessTokenExpires.toIso8601String(),
      ),
      _storage.write(
        key: _refreshTokenExpiresKey,
        value: tokens.refreshTokenExpires.toIso8601String(),
      ),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readAccessTokenExpires() async {
    final value = await _storage.read(key: _accessTokenExpiresKey);
    return value == null ? null : DateTime.parse(value);
  }

  Future<DateTime?> readRefreshTokenExpires() async {
    final value = await _storage.read(key: _refreshTokenExpiresKey);
    return value == null ? null : DateTime.parse(value);
  }

  Future<bool> hasTokens() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    return access != null && refresh != null;
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessTokenExpiresKey),
      _storage.delete(key: _refreshTokenExpiresKey),
    ]);
  }
}
