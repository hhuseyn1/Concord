// Exercises `app_router.dart`'s `concord://` deep-link handling end to end (custom-scheme URI ->
// normalized in-app path -> route match/redirect), since there's no Android/iOS device or emulator
// available in this environment to tap an actual OS-level deep link and confirm the manifest/plist
// wiring hands it to the app the way `flutter build apk`/`flutter build ios` alone can't verify.
import 'package:concord/api/api.dart';
import 'package:concord/main.dart';
import 'package:concord/providers/api_providers.dart';
import 'package:concord/providers/deep_link_providers.dart';
import 'package:concord/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<bool> hasTokens() async => false;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<DateTime?> readAccessTokenExpires() async => null;

  @override
  Future<DateTime?> readRefreshTokenExpires() async => null;

  @override
  Future<void> saveTokens(TokenResponse tokens) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('concord://reset-password?token=... opens the reset-password screen', (tester) async {
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const ConcordApp()));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('concord://reset-password?token=abc123');
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('concord:///reset-password (triple-slash form) also matches', (tester) async {
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const ConcordApp()));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('concord:///reset-password?token=abc123');
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('a reset-password link with no token shows the invalid-link state', (tester) async {
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const ConcordApp()));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('concord://reset-password');
    await tester.pumpAndSettle();

    expect(find.text('Invalid reset link'), findsOneWidget);
  });

  testWidgets('concord://invite/{code} stashes the code and still requires login when signed out', (tester) async {
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const ConcordApp()));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('concord://invite/ABC123');
    await tester.pumpAndSettle();

    // No session yet, so it's bounced to /login same as any other route — but the code survives.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(container.read(pendingInviteCodeProvider), 'ABC123');
  });
}
