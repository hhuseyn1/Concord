import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../utils/permission_rationale.dart';
import 'api_providers.dart';
import 'auth_controller.dart';

class PushNotificationsState {
  const PushNotificationsState();
}

class PushNotificationsController extends StateNotifier<PushNotificationsState> {
  PushNotificationsController(this._ref) : super(const PushNotificationsState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (!isAuthenticated && wasAuthenticated) unawaited(_deregisterToken());
    });
  }

  final Ref _ref;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;
  bool _attempted = false;

  Future<void> ensureRegistered(BuildContext context) async {
    if (_attempted) return;
    _attempted = true;

    final l10n = AppLocalizations.of(context);
    final granted = await requestPermissionWithRationale(
      context,
      permission: Permission.notification,
      title: l10n.notificationAccessTitle,
      rationale: l10n.notificationAccessRationale,
    );
    if (!granted) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (_) {
    }

    _refreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => unawaited(_sendToken(token)),
    );
  }

  Future<void> _sendToken(String token) async {
    try {
      await _ref.read(usersServiceProvider).registerPushToken(token);
      _registeredToken = token;
    } catch (_) {
    }
  }

  Future<void> _deregisterToken() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    _attempted = false;

    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _ref.read(usersServiceProvider).deregisterPushToken(token);
    } catch (_) {
    }
  }

  @override
  void dispose() {
    unawaited(_refreshSubscription?.cancel());
    super.dispose();
  }
}

final pushNotificationsControllerProvider =
    StateNotifierProvider<PushNotificationsController, PushNotificationsState>((ref) {
  return PushNotificationsController(ref);
});
