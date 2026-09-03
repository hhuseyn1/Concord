import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.profile});

  final AuthStatus status;

  final MyProfileResponse? profile;

  AuthState copyWith({AuthStatus? status, MyProfileResponse? profile, bool clearProfile = false}) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(status: AuthStatus.unknown)) {
    _checkInitialSession();
  }

  final Ref _ref;

  AuthService get _authService => _ref.read(authServiceProvider);
  TokenStorage get _tokenStorage => _ref.read(tokenStorageProvider);
  UsersService get _usersService => _ref.read(usersServiceProvider);
  SessionsService get _sessionsService => _ref.read(sessionsServiceProvider);

  Future<void> _checkInitialSession() async {
    final hasTokens = await _tokenStorage.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(status: AuthStatus.unauthenticated, clearProfile: true);
      return;
    }
    state = state.copyWith(status: AuthStatus.authenticated);
    unawaited(_loadProfile());
  }

  Future<void> login({required String email, required String password}) async {
    await _authService.login(email: email, password: password);
    state = state.copyWith(status: AuthStatus.authenticated);
    unawaited(_loadProfile());
  }

  Future<void> completeTwoFactorLogin({required String twoFactorToken, required String code}) async {
    await _authService.completeTwoFactorLogin(twoFactorToken: twoFactorToken, code: code);
    state = state.copyWith(status: AuthStatus.authenticated);
    unawaited(_loadProfile());
  }

  Future<void> register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    await _authService.register(name: name, surname: surname, email: email, password: password);
    state = state.copyWith(status: AuthStatus.authenticated);
    unawaited(_loadProfile());
  }

  Future<void> logout() async {
    // Best-effort server-side session revocation: this tells the backend to
    // invalidate the refresh token immediately instead of leaving it valid
    // until natural expiry. It must never block or fail the user-visible
    // logout — if the access token is already expired this call may 401 and
    // trigger the API client's refresh-then-retry logic, which itself may
    // fail (e.g. offline, refresh token already invalid); either way we
    // swallow the error and fall through to clearing local tokens, which is
    // what actually logs the user out on-device.
    try {
      await _sessionsService.revokeCurrentSession();
    } catch (_) {
      // Ignore: local logout must proceed regardless of server outcome.
    }
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleSessionExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _usersService.getMe();
      if (state.status == AuthStatus.authenticated) {
        state = state.copyWith(profile: profile);
      }
    } on ApiException {
      // ignore: empty_catches
    }
  }

  Future<void> refreshProfile() => _loadProfile();

  void setProfile(MyProfileResponse profile) {
    if (state.status != AuthStatus.authenticated) return;
    state = state.copyWith(profile: profile);
  }
}
