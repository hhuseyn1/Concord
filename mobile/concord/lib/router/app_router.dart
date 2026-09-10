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
      GoRoute(path: '/invite/:code', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(path: '/', builder: (context, state) => const _RootGate()),
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

/// The `/` route's builder runs inside [routerProvider]'s own closure, whose `ref` is a
/// [Provider]-scoped ref captured once when the (long-lived, cached) [GoRouter] is built - reading
/// [authControllerProvider] there with `ref.read` used to snapshot the status only at that one
/// moment. Once local tokens resolved to `authenticated` shortly after launch, the top-level
/// `redirect` saw we were already at `/` and returned null (nothing to redirect), so the stale
/// snapshot was never replaced and the splash spinner stuck around forever. Routing that decision
/// through a real widget-tree [ConsumerWidget] with `ref.watch` fixes that: this widget rebuilds
/// itself whenever auth status changes, independent of whether GoRouter itself re-navigates.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider.select((state) => state.status));
    return status == AuthStatus.unknown ? const SplashScreen() : const HomeScreen();
  }
}

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}
