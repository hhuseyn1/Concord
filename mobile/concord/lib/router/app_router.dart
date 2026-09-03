import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_controller.dart';
import '../providers/deep_link_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/direct_messages/direct_message_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/servers/server_member_list_screen.dart';
import '../screens/shell/channel_list_screen.dart';
import '../screens/shell/channel_screen.dart';
import '../screens/shell/home_screen.dart';
import '../screens/splash_screen.dart';

/// Invite links (`concord://invite/{code}`) and password-reset links (`concord://reset-password?
/// token=...`) are the two deep link shapes wired up so far (a basic custom `concord://` scheme —
/// see the Android manifest's intent-filter and iOS's `CFBundleURLTypes` — not an https App Link,
/// which would need a domain and a hosted verification file this project doesn't have).
///
/// A custom-scheme `Uri` can serialize its first path segment as either the URI's host
/// (`concord://invite/CODE` -> host `invite`, path `/CODE`) or, with a doubled slash, as an ordinary
/// path segment (`concord:///invite/CODE` -> host empty, path `/invite/CODE`) depending on how the
/// platform hands it off. This folds both shapes into one in-app path/query and re-enters the
/// redirect pipeline against it, so route matching below only ever has to deal with ordinary paths.
String? _normalizeConcordDeepLink(Uri uri) {
  if (uri.scheme != 'concord') return null;
  final segments = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
  final path = segments.isEmpty ? '/' : '/${segments.join('/')}';
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final normalized = _normalizeConcordDeepLink(state.uri);
      if (normalized != null) return normalized;

      final matchedLocation = state.matchedLocation;

      // `/invite/{code}` is deep-link-only — joining a server happens through a modal bottom sheet
      // (`showAddServerSheet`), not a routable screen, so there's no matching `GoRoute` for it below.
      // Stash the code and always redirect elsewhere; `HomeScreen` picks it up via
      // `pendingInviteCodeProvider` once the user is authenticated (surviving an interim bounce
      // through `/login` below, since the provider is global).
      final isInviteDeepLink = matchedLocation.startsWith('/invite/');
      if (isInviteDeepLink) {
        final code = Uri.decodeComponent(matchedLocation.substring('/invite/'.length));
        if (code.isNotEmpty) ref.read(pendingInviteCodeProvider.notifier).state = code;
      }

      final authState = ref.read(authControllerProvider);
      final isAuthRoute = matchedLocation == '/login' || matchedLocation == '/register';
      final isPasswordResetRoute = matchedLocation == '/reset-password';

      switch (authState.status) {
        case AuthStatus.unknown:
          return isInviteDeepLink ? '/' : null;
        case AuthStatus.unauthenticated:
          if (!isInviteDeepLink && (isAuthRoute || isPasswordResetRoute)) return null;
          return '/login';
        case AuthStatus.authenticated:
          if (isInviteDeepLink) return '/';
          return isAuthRoute ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      // `/invite/:code` has no real screen of its own (see the top-level `redirect` above, which
      // always sends it somewhere else — `/login` or `/`) — it only needs to exist here so go_router's
      // route matcher can resolve it at all while the normalized `concord://invite/...` location is in
      // flight; without a matching route here, go_router treats that in-flight location as a dead end
      // ("no routes for location") before the top-level redirect gets a chance to run a second time.
      GoRoute(path: '/invite/:code', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final status = ref.read(authControllerProvider).status;
          return status == AuthStatus.unknown ? const SplashScreen() : const HomeScreen();
        },
      ),
      GoRoute(
        path: '/servers/:serverId',
        builder: (context, state) {
          final serverId = state.pathParameters['serverId']!;
          return ChannelListScreen(serverId: serverId);
        },
      ),
      GoRoute(
        path: '/servers/:serverId/channels/:channelId',
        builder: (context, state) {
          final serverId = state.pathParameters['serverId']!;
          final channelId = state.pathParameters['channelId']!;
          return ChannelScreen(serverId: serverId, channelId: channelId);
        },
      ),
      GoRoute(
        path: '/servers/:serverId/members',
        builder: (context, state) {
          final serverId = state.pathParameters['serverId']!;
          return ServerMemberListScreen(serverId: serverId);
        },
      ),
      GoRoute(
        path: '/dm/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return DirectMessageScreen(
            conversationId: conversationId,
            args: state.extra as DirectMessageRouteArgs?,
          );
        },
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
  );
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}
