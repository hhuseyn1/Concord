// Smoke test for the real app shell (replaces the counter-demo smoke test
// that shipped with the Flutter project template — main.dart is no longer a
// counter demo as of Phase 2).
//
// Overrides `tokenStorageProvider` with an in-memory fake so the test never
// touches `flutter_secure_storage`'s platform channel (unavailable/unmocked
// under `flutter test`), then asserts the unauthenticated app renders the
// login screen — the same "no session -> RequireAuth sends you to /login"
// behavior as the web app's route guard.
import 'package:concord/api/api.dart';
import 'package:concord/main.dart';
import 'package:concord/providers/api_providers.dart';
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
  testWidgets('unauthenticated app builds and lands on the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const ConcordApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
