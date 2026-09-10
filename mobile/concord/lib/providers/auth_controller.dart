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

  /// Registration requires email confirmation before the account can log in, so - unlike
  /// [login] - this never transitions [state] to authenticated. A successful call just means the
  /// verification email was sent; the caller shows a "check your email" state and the user logs
  /// in separately once confirmed.
  Future<void> register({
    required String name,
    required String surname,
    required String username,
    required String email,
    required String password,
  }) async {
    await _authService.register(
      name: name,
      surname: surname,
      username: username,
      email: email,
      password: password,
    );
  }

  Future<void> resendVerificationEmail({required String email}) {
    return _authService.resendVerificationEmail(email: email);
  }

  Future<void> logout() async {
    try {
      await _sessionsService.revokeCurrentSession();
    } catch (_) {
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
    }
  }

  Future<void> refreshProfile() => _loadProfile();

  void setProfile(MyProfileResponse profile) {
    if (state.status != AuthStatus.authenticated) return;
    state = state.copyWith(profile: profile);
  }
}
