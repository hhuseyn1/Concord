import 'api_client.dart';
import 'api_exception.dart';
import 'models/json_utils.dart';
import 'models/recovery_codes_response.dart';
import 'models/token_response.dart';
import 'models/two_factor_setup_response.dart';
import 'models/two_factor_status_response.dart';
import 'token_storage.dart';

class AuthService {
  AuthService(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<TokenResponse> login({required String email, required String password}) async {
    final data = await _client.post(
      '/Login',
      body: {'Email': email, 'Password': password},
      auth: false,
    ) as Map<String, dynamic>;

    if (data.field('TwoFactorRequired') == true) {
      throw ApiException(
        ApiException.twoFactorRequiredStatusCode,
        'This account has two-factor authentication enabled.',
        twoFactorToken: data.field('TwoFactorToken') as String?,
      );
    }

    final tokens = TokenResponse.fromJson(data);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  Future<TokenResponse> completeTwoFactorLogin({
    required String twoFactorToken,
    required String code,
  }) async {
    final data = await _client.post(
      '/Login/TwoFactor',
      body: {'TwoFactorToken': twoFactorToken, 'Code': code, 'RememberMe': false},
      auth: false,
    );
    final tokens = TokenResponse.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  Future<TokenResponse> register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/Register',
      body: {'Name': name, 'Surname': surname, 'Email': email, 'Password': password},
      auth: false,
    );
    final tokens = TokenResponse.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  Future<void> resetPassword({required String userId, required String newPassword}) async {
    await _client.post('/$userId:Reset-password', body: {'NewPassword': newPassword});
  }

  /// Confirms a password reset using the token from an emailed reset link
  /// (`concord://reset-password?token=...` on mobile, `/reset-password?token=...` on web) — the
  /// public, unauthenticated counterpart to the admin-facing [resetPassword] above. Matches the
  /// backend's `POST /Reset-password`, which revokes every existing session on success.
  Future<void> confirmPasswordReset({required String token, required String newPassword}) async {
    await _client.post(
      '/Reset-password',
      body: {'Token': token, 'NewPassword': newPassword},
      auth: false,
    );
  }

  Future<TokenResponse> refresh() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    final data = await _client.post(
      '/Refresh',
      body: {'AccessToken': accessToken, 'RefreshToken': refreshToken},
      auth: false,
    );
    final tokens = TokenResponse.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _client.post(
      '/Me:Change-password',
      body: {'CurrentPassword': currentPassword, 'NewPassword': newPassword},
    );
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<TwoFactorStatusResponse> getTwoFactorStatus() async {
    final data = await _client.get('/Me/TwoFactor');
    return TwoFactorStatusResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Begins enrolment: mints a secret and returns it as a QR (server-rendered SVG) plus a typeable
  /// key. Two-factor is not yet active - the secret stays inert until confirmed via [enableTwoFactor].
  Future<TwoFactorSetupResponse> startTwoFactorSetup() async {
    final data = await _client.post('/Me/TwoFactor/Setup');
    return TwoFactorSetupResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Confirms enrolment with a code from the authenticator and returns the recovery codes. Those
  /// codes are shown exactly once - only their hashes are kept server-side.
  Future<RecoveryCodesResponse> enableTwoFactor({required String code}) async {
    final data = await _client.post('/Me/TwoFactor/Enable', body: {'Code': code});
    return RecoveryCodesResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> disableTwoFactor({required String password, required String code}) async {
    await _client.post('/Me/TwoFactor/Disable', body: {'Password': password, 'Code': code});
  }

  Future<RecoveryCodesResponse> regenerateRecoveryCodes({required String password}) async {
    final data = await _client.post('/Me/TwoFactor/Recovery-Codes', body: {'Password': password});
    return RecoveryCodesResponse.fromJson(data as Map<String, dynamic>);
  }
}
