import 'package:concord/api/api.dart';
import 'package:concord/l10n/app_localizations.dart';
import 'package:concord/providers/api_providers.dart';
import 'package:concord/providers/auth_controller.dart';
import 'package:concord/providers/font_scale_provider.dart';
import 'package:concord/screens/settings/appearance_section.dart';
import 'package:concord/screens/settings/send_stars_sheet.dart';
import 'package:concord/screens/settings/settings_screen.dart';
import 'package:concord/screens/settings/stars_section.dart';
import 'package:concord/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


const _phoneWidths = <double>[320, 375, 390, 430];

final _heightForWidth = <double, double>{320: 568, 375: 667, 390: 844, 430: 932};

class _FakeStarsService extends StarsService {
  _FakeStarsService() : super(ApiClient(tokenStorage: TokenStorage()));

  static const balance = 1250;

  @override
  Future<StarWalletResponse> getWallet() async => StarWalletResponse.fromJson({
        'Balance': balance,
        'PremiumTrialActive': false,
        'PremiumTrialExpiresAt': null,
        'HasActivePremium': false,
      });

  @override
  Future<StarsConfigResponse> getConfig() async => StarsConfigResponse.fromJson({
        'ChatRewardAmount': 2,
        'ChatRewardCooldownSeconds': 30,
        'ChatRewardDailyCap': 50,
        'PremiumTrialCostStars': 500,
        'PremiumTrialDurationDays': 14,
        'Packages': [
          {'Id': 'stars_100', 'Stars': 100, 'PriceAmount': 0.99, 'Currency': 'usd'},
          {'Id': 'stars_500', 'Stars': 500, 'PriceAmount': 3.99, 'Currency': 'usd'},
          {'Id': 'stars_1000', 'Stars': 1000, 'PriceAmount': 6.99, 'Currency': 'usd'},
          {'Id': 'stars_5000', 'Stars': 5000, 'PriceAmount': 29.99, 'Currency': 'usd'},
        ],
      });

  @override
  Future<PagedResult<StarTransactionResponse>> getTransactions({int page = 1, int pageSize = 20}) async {
    return PagedResult.fromJson({
      'Items': [
        {
          'Id': 'tx-1',
          'Type': 'ChatReward',
          'Amount': 2,
          'BalanceAfter': 1250,
          'CounterpartyUsername': null,
          'Created': '2026-09-15T10:00:00Z',
        },
        {
          'Id': 'tx-2',
          'Type': 'TransferSent',
          'Amount': -500,
          'BalanceAfter': 1248,
          'CounterpartyUsername': 'a_very_long_username_indeed_42',
          'Created': '2026-09-14T09:30:00Z',
        },
        {
          'Id': 'tx-3',
          'Type': 'PackagePurchase',
          'Amount': 5000,
          'BalanceAfter': 6248,
          'CounterpartyUsername': null,
          'Created': '2026-09-13T08:00:00Z',
        },
      ],
      'Page': 1,
      'PageSize': 20,
      'TotalCount': 40,
    }, StarTransactionResponse.fromJson);
  }
}

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<bool> hasTokens() async => true;

  @override
  Future<String?> readAccessToken() async => 'test-access-token';

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

MyProfileResponse _longProfile() => MyProfileResponse.fromJson({
      'Id': 'me',
      'Username': 'a_pretty_long_display_username',
      'Name': 'Test',
      'Surname': 'Person',
      'Email': 'a.very.long.email.address@example-domain.com',
      'PhoneNumber': null,
      'AvatarUrl': null,
      'Locale': 'en',
      'NotificationsMuted': false,
      'NotificationsSoundEnabled': true,
      'Status': 'Online',
      'CustomStatusEmoji': null,
      'CustomStatusText': 'Working on something fairly long here',
      'CustomStatusExpiresAt': null,
      'FriendRequestPrivacy': 'Everyone',
      'DirectMessagePrivacy': 'Everyone',
      'ActivityVisibility': 'Everyone',
      'ReadReceiptsEnabled': true,
      'Created': '2026-01-01T00:00:00Z',
      'ActivityApplicationName': null,
      'ActivityType': null,
      'ActivityStartedAt': null,
    });

class _FakeFriendsService extends FriendsService {
  _FakeFriendsService() : super(ApiClient(tokenStorage: TokenStorage()));

  @override
  Future<PagedResult<PublicProfileResponse>> listFriends({int page = 1, int pageSize = 30}) async {
    return PagedResult.fromJson({
      'Items': [
        _friend('friend-1', 'alex'),
        _friend('friend-2', 'a_rather_long_friend_username_here'),
        _friend('friend-3', 'sam'),
      ],
      'Page': 1,
      'PageSize': 30,
      'TotalCount': 60,
    }, PublicProfileResponse.fromJson);
  }

  static Map<String, dynamic> _friend(String id, String username) => {
        'Id': id,
        'Username': username,
        'Name': 'Test',
        'Surname': 'Friend',
        'AvatarUrl': null,
        'Created': '2026-01-01T00:00:00Z',
        'Status': 'Online',
        'LastSeenAt': null,
        'CustomStatusEmoji': null,
        'CustomStatusText': null,
        'RelationshipStatus': 'Friends',
        'PendingRequestId': null,
        'MutualFriendsCount': 0,
        'ActivityApplicationName': null,
        'ActivityType': null,
        'ActivityStartedAt': null,
      };
}

Future<void> _pumpAt(
  WidgetTester tester, {
  required double width,
  required double fontScale,
  required Brightness brightness,
  required Widget child,
  bool wrapInScaffold = true,
}) async {
  final height = _heightForWidth[width]!;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        starsServiceProvider.overrideWithValue(_FakeStarsService()),
        friendsServiceProvider.overrideWithValue(_FakeFriendsService()),
        tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? ConcordTheme.dark(fontScale: fontScale)
            : ConcordTheme.light(fontScale: fontScale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final width in _phoneWidths) {
    for (final option in [FontScaleOption.small, FontScaleOption.extraLarge]) {
      for (final brightness in Brightness.values) {
        final label = '${width.toInt()}pt / ${option.name} text / ${brightness.name}';

        testWidgets('Stars tab lays out without overflow at $label', (tester) async {
          await _pumpAt(
            tester,
            width: width,
            fontScale: option.scale,
            brightness: brightness,
            child: const StarsSection(),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Your balance'.toUpperCase()), findsOneWidget);

          await tester.scrollUntilVisible(find.text('Buy Stars'), 200);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.text('Recent activity'), 200);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('Appearance section lays out without overflow at $label', (tester) async {
          await _pumpAt(
            tester,
            width: width,
            fontScale: option.scale,
            brightness: brightness,
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(ConcordSpacing.lg),
              child: AppearanceSection(),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Appearance'), findsOneWidget);

          await tester.tap(find.text('Theme'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Light'), findsOneWidget);
          expect(find.text('Dark'), findsOneWidget);

          await tester.tap(find.text('Light'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Light'), findsOneWidget);

          await tester.tap(find.text('Text size'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('Extra large'), findsOneWidget);
        });

        testWidgets('Settings screen lays out without overflow at $label', (tester) async {
          await _pumpAt(
            tester,
            width: width,
            fontScale: option.scale,
            brightness: brightness,
            child: const SettingsScreen(),
            wrapInScaffold: false,
          );

          final container = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
          container.read(authControllerProvider.notifier).setProfile(_longProfile());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('My Account'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Stars'),
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(find.text('a_pretty_long_display_username'), findsOneWidget);
          expect(find.text('Edit Profile'), findsOneWidget);

          await tester.tap(find.byType(StarsBalanceChip));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Your balance'.toUpperCase()), findsOneWidget);
        });

        testWidgets('Send Stars sheet lays out without overflow at $label', (tester) async {
          await _pumpAt(
            tester,
            width: width,
            fontScale: option.scale,
            brightness: brightness,
            child: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showSendStarsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          );

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Send to'), findsOneWidget);
          expect(find.text('alex'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('Amount', findRichText: true),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Send'),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
