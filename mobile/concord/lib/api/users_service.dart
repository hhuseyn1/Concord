import 'api_client.dart';
import 'models/enums.dart';
import 'models/my_profile_response.dart';
import 'models/public_profile_response.dart';

class UsersService {
  UsersService(this._client);

  final ApiClient _client;

  Future<MyProfileResponse> getMe() async {
    final data = await _client.get('/Users/Me');
    return MyProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MyProfileResponse> updateMe({
    required String name,
    required String surname,
    required String username,
    String? avatarUrl,
  }) async {
    final data = await _client.put(
      '/Users/Me',
      body: {'Name': name, 'Surname': surname, 'Username': username, 'AvatarUrl': avatarUrl},
    );
    return MyProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MyProfileResponse> updatePreferences({
    String? locale,
    required bool notificationsMuted,
    required bool notificationsSoundEnabled,
  }) async {
    final data = await _client.put(
      '/Users/Me/Preferences',
      body: {
        'Locale': locale,
        'NotificationsMuted': notificationsMuted,
        'NotificationsSoundEnabled': notificationsSoundEnabled,
      },
    );
    return MyProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MyProfileResponse> updatePrivacy({
    required FriendRequestPrivacy friendRequestPrivacy,
    required DirectMessagePrivacy directMessagePrivacy,
    required ActivityVisibility activityVisibility,
    required bool readReceiptsEnabled,
  }) async {
    final data = await _client.put(
      '/Users/Me/Privacy',
      body: {
        'FriendRequestPrivacy': friendRequestPrivacy.toWire(),
        'DirectMessagePrivacy': directMessagePrivacy.toWire(),
        'ActivityVisibility': activityVisibility.toWire(),
        'ReadReceiptsEnabled': readReceiptsEnabled,
      },
    );
    return MyProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MyProfileResponse> updateCustomStatus({
    required String emoji,
    required String text,
    required CustomStatusExpiryPreset expiryPreset,
  }) async {
    final data = await _client.put(
      '/Users/Me/CustomStatus',
      body: {'Emoji': emoji, 'Text': text, 'ExpiryPreset': expiryPreset.toWire()},
    );
    return MyProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PublicProfileResponse> getUser(String userId) async {
    final data = await _client.get('/Users/$userId');
    return PublicProfileResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PublicProfileResponse>> search(String query) async {
    final data = await _client.get('/Users/Search', query: {'query': query});
    return (data as List<dynamic>)
        .map((e) => PublicProfileResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
