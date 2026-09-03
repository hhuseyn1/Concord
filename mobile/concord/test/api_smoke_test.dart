// Smoke test for the API/data-access layer under lib/api/.
//
// This deliberately does not hit a real backend (no guarantee one is
// running wherever this executes) — it instead exercises the pure-Dart
// parts that are easiest to get wrong silently: model (de)serialization
// against both REST's PascalCase wire shape and SignalR's camelCase wire
// shape (see lib/api/models/json_utils.dart), enum wire-format mapping,
// pagination parsing, and that every client/service/hub class constructs
// without touching a platform channel eagerly.
import 'package:concord/api/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enums (int wire format over hubs, string wire format over REST)', () {
    test('PresenceStatus round-trips through the real ordinal (hub) wire format', () {
      expect(PresenceStatus.fromWire(0), PresenceStatus.online);
      expect(PresenceStatus.fromWire(1), PresenceStatus.idle);
      expect(PresenceStatus.fromWire(2), PresenceStatus.doNotDisturb);
      expect(PresenceStatus.fromWire(3), PresenceStatus.invisible);
      expect(PresenceStatus.fromWire(4), PresenceStatus.offline);
      expect(PresenceStatus.online.toWire(), 0);
      expect(PresenceStatus.idle.toWire(), 1);
      expect(PresenceStatus.doNotDisturb.toWire(), 2);
      expect(PresenceStatus.invisible.toWire(), 3);
      expect(PresenceStatus.offline.toWire(), 4);
    });

    test('PresenceStatus also parses the real REST (string) wire format', () {
      expect(PresenceStatus.fromWire('Online'), PresenceStatus.online);
      expect(PresenceStatus.fromWire('DoNotDisturb'), PresenceStatus.doNotDisturb);
      expect(PresenceStatus.fromWire('Invisible'), PresenceStatus.invisible);
      expect(PresenceStatus.fromWire('Offline'), PresenceStatus.offline);
    });

    test('ChannelType/FriendRequestStatus/NotificationType ordinals', () {
      expect(ChannelType.fromWire(0), ChannelType.text);
      expect(ChannelType.fromWire(1), ChannelType.voice);
      expect(FriendRequestStatus.fromWire(0), FriendRequestStatus.pending);
      expect(FriendRequestStatus.fromWire(1), FriendRequestStatus.accepted);
      expect(NotificationType.fromWire(0), NotificationType.friendRequestReceived);
      expect(NotificationType.fromWire(1), NotificationType.friendRequestAccepted);
      expect(NotificationType.fromWire(2), NotificationType.missedCall);
      expect(NotificationType.fromWire(3), NotificationType.mention);
    });

    test('FriendRelationshipStatus/ActivityType/privacy enums parse both wire shapes', () {
      expect(FriendRelationshipStatus.fromWire(2), FriendRelationshipStatus.outgoingRequest);
      expect(FriendRelationshipStatus.fromWire('IncomingRequest'), FriendRelationshipStatus.incomingRequest);
      expect(ActivityType.fromWire(3), ActivityType.using);
      expect(ActivityType.fromWire('Coding'), ActivityType.coding);
      expect(FriendRequestPrivacy.fromWire('FriendsOfFriends'), FriendRequestPrivacy.friendsOfFriends);
      expect(DirectMessagePrivacy.fromWire('FriendsOnly'), DirectMessagePrivacy.friendsOnly);
      expect(ActivityVisibility.fromWire('Nobody'), ActivityVisibility.nobody);
    });
  });

  group('PublicProfileResponse.fromJson', () {
    final pascalCaseJson = {
      'Id': 'a1b2',
      'Username': 'huseyn',
      'Name': 'Huseyn',
      'Surname': 'Hemidov',
      'AvatarUrl': '/uploads/avatars/x.png',
      'Created': '2026-01-01T00:00:00Z',
      'Status': 'Online',
      'LastSeenAt': null,
      'CustomStatusEmoji': null,
      'CustomStatusText': null,
      'RelationshipStatus': 'Friends',
      'PendingRequestId': null,
      'MutualFriendsCount': 3,
      'ActivityApplicationName': null,
      'ActivityType': null,
      'ActivityStartedAt': null,
    };

    test('parses REST-shaped (PascalCase) JSON', () {
      final profile = PublicProfileResponse.fromJson(pascalCaseJson);
      expect(profile.id, 'a1b2');
      expect(profile.username, 'huseyn');
      expect(profile.status, PresenceStatus.online);
      expect(profile.lastSeenAt, isNull);
      expect(profile.relationshipStatus, FriendRelationshipStatus.friends);
      expect(profile.mutualFriendsCount, 3);
    });

    test('also parses hub-shaped (camelCase) JSON via the same fromJson', () {
      final camelCaseJson = {
        for (final entry in pascalCaseJson.entries)
          '${entry.key[0].toLowerCase()}${entry.key.substring(1)}': entry.value,
      };
      final profile = PublicProfileResponse.fromJson(camelCaseJson);
      expect(profile.id, 'a1b2');
      expect(profile.status, PresenceStatus.online);
      expect(profile.mutualFriendsCount, 3);
    });
  });

  test('PagedResult.fromJson parses Items/Page/PageSize/TotalCount', () {
    final json = {
      'Items': [
        {
          'Id': '1',
          'Name': 'general',
          'ServerId': 's1',
          'Type': 'Text',
          'Created': '2026-01-01T00:00:00Z',
          'UnreadCount': 5,
        },
      ],
      'Page': 1,
      'PageSize': 30,
      'TotalCount': 1,
    };
    final result = PagedResult.fromJson(json, ChannelResponse.fromJson);
    expect(result.items, hasLength(1));
    expect(result.items.single.type, ChannelType.text);
    expect(result.items.single.unreadCount, 5);
    expect(result.page, 1);
    expect(result.totalCount, 1);
    expect(result.hasNextPage, isFalse);
  });

  test('ApiException.isLikelyAccountLockout matches the documented lockout message', () {
    // UserLockoutException inherits UnauthorizedAccessException server-side, so this is a 401,
    // same status as plain bad credentials — see ApiException.isLikelyAccountLockout's doc comment.
    const lockout = ApiException(
      401,
      "User '123' has exceeded the number of allowed authentication attempts.",
    );
    expect(lockout.isLikelyAccountLockout, isTrue);

    const badCredentials = ApiException(401, 'Invalid email or password.');
    expect(badCredentials.isLikelyAccountLockout, isFalse);

    const genericServerError = ApiException(500, 'Internal Server Error');
    expect(genericServerError.isLikelyAccountLockout, isFalse);
  });

  test('MessageResponse.fromJson parses a nested Sender profile', () {
    final json = {
      'Id': 'm1',
      'ChannelId': 'c1',
      'Sender': {
        'Id': 'u1',
        'Username': 'huseyn',
        'Name': null,
        'Surname': null,
        'AvatarUrl': null,
        'Created': '2026-01-01T00:00:00Z',
        'Status': 'Offline',
        'LastSeenAt': '2026-01-02T00:00:00Z',
        'MutualFriendsCount': 0,
      },
      'Content': 'hello',
      'Created': '2026-01-01T00:00:00Z',
      'EditedAtUtc': null,
      'AttachmentUrl': null,
    };
    final message = MessageResponse.fromJson(json);
    expect(message.sender.status, PresenceStatus.offline);
    expect(message.content, 'hello');
    expect(message.reactions, isEmpty);
    expect(message.mentionedUserIds, isEmpty);
    expect(message.replyToMessageId, isNull);
  });

  test('MessageResponse.fromJson tolerates a null Content (attachment-only message)', () {
    final json = {
      'Id': 'm2',
      'ChannelId': 'c1',
      'Sender': {
        'Id': 'u1',
        'Username': 'huseyn',
        'Created': '2026-01-01T00:00:00Z',
        'Status': 'Offline',
        'MutualFriendsCount': 0,
      },
      'Content': null,
      'Created': '2026-01-01T00:00:00Z',
      'AttachmentUrl': '/uploads/x.png',
      'ReplyToMessageId': 'm1',
      'Reactions': [
        {'Emoji': '👍', 'UserIds': ['u1', 'u2']},
      ],
      'MentionedUserIds': ['u3'],
    };
    final message = MessageResponse.fromJson(json);
    expect(message.content, isNull);
    expect(message.attachmentUrl, '/uploads/x.png');
    expect(message.replyToMessageId, 'm1');
    expect(message.reactions, hasLength(1));
    expect(message.reactions.single.emoji, '👍');
    expect(message.reactions.single.userIds, ['u1', 'u2']);
    expect(message.mentionedUserIds, ['u3']);
  });

  test('MessageResponse.fromJson parses pin/forward fields from both wire shapes', () {
    final restJson = {
      'Id': 'm3',
      'ChannelId': 'c1',
      'Sender': {
        'Id': 'u1',
        'Username': 'huseyn',
        'Created': '2026-01-01T00:00:00Z',
        'Status': 'Offline',
        'MutualFriendsCount': 0,
      },
      'Content': 'pinned message',
      'Created': '2026-01-01T00:00:00Z',
      'PinnedAt': '2026-01-03T00:00:00Z',
      'PinnedByUserId': 'u2',
      'ForwardedFromSenderId': 'u3',
      'ForwardedFromCreatedAt': '2025-12-31T00:00:00Z',
    };
    final restMessage = MessageResponse.fromJson(restJson);
    expect(restMessage.pinnedAt, DateTime.parse('2026-01-03T00:00:00Z'));
    expect(restMessage.pinnedByUserId, 'u2');
    expect(restMessage.forwardedFromSenderId, 'u3');
    expect(restMessage.forwardedFromCreatedAt, DateTime.parse('2025-12-31T00:00:00Z'));

    // Same shape, camelCase (hub payload) — same case-insensitive `field`
    // lookup this whole model relies on, see json_utils.dart.
    final hubJson = {
      'id': 'm3',
      'channelId': 'c1',
      'sender': restJson['Sender'],
      'content': 'pinned message',
      'created': '2026-01-01T00:00:00Z',
      'pinnedAt': '2026-01-03T00:00:00Z',
      'pinnedByUserId': 'u2',
    };
    final hubMessage = MessageResponse.fromJson(hubJson);
    expect(hubMessage.pinnedAt, DateTime.parse('2026-01-03T00:00:00Z'));
    expect(hubMessage.pinnedByUserId, 'u2');
  });

  test('TypingEvent.fromJson parses the camelCase UserTyping/UserStoppedTyping hub payload', () {
    final event = TypingEvent.fromJson({'channelId': 'c1', 'userId': 'u1'});
    expect(event.channelId, 'c1');
    expect(event.userId, 'u1');
  });

  group('construction (no network / no platform-channel calls made)', () {
    test('TokenStorage, ApiClient and every *Service construct cleanly', () {
      final tokenStorage = TokenStorage();
      final client = ApiClient(tokenStorage: tokenStorage);

      expect(AuthService(client, tokenStorage), isNotNull);
      expect(UsersService(client), isNotNull);
      expect(FriendsService(client), isNotNull);
      expect(ServersService(client), isNotNull);
      expect(ChannelsService(client), isNotNull);
      expect(MessagesService(client), isNotNull);
      expect(DirectMessagesService(client), isNotNull);
      expect(FilesService(client), isNotNull);
      expect(NotificationsService(client), isNotNull);
      expect(VoiceService(client), isNotNull);
    });

    test('hub wrappers construct without connecting', () {
      final tokenStorage = TokenStorage();
      expect(MessagesHub(tokenStorage: tokenStorage), isNotNull);
      expect(DirectMessagesHub(tokenStorage: tokenStorage), isNotNull);
      expect(PresenceHub(tokenStorage: tokenStorage), isNotNull);
      expect(NotificationsHub(tokenStorage: tokenStorage), isNotNull);
      expect(VoiceHub(tokenStorage: tokenStorage), isNotNull);
    });
  });

  group('DirectMessageResponse/ConversationResponse.fromJson', () {
    final senderJson = {
      'Id': 'u1',
      'Username': 'huseyn',
      'Created': '2026-01-01T00:00:00Z',
      'Status': 'Online',
      'MutualFriendsCount': 0,
    };

    test('DirectMessageResponse.fromJson parses ConversationId (not ChannelId)', () {
      final message = DirectMessageResponse.fromJson({
        'Id': 'm1',
        'ConversationId': 'c1',
        'Sender': senderJson,
        'Content': 'hey',
        'Created': '2026-01-01T00:00:00Z',
      });
      expect(message.conversationId, 'c1');
      expect(message.content, 'hey');
      expect(message.sender.username, 'huseyn');
      expect(message.reactions, isEmpty);
      expect(message.mentionedUserIds, isEmpty);
    });

    test('DirectMessageResponse implements MessageLike', () {
      final message = DirectMessageResponse.fromJson({
        'Id': 'm1',
        'ConversationId': 'c1',
        'Sender': senderJson,
        'Content': 'hey',
        'Created': '2026-01-01T00:00:00Z',
      });
      final MessageLike asMessageLike = message;
      expect(asMessageLike.id, 'm1');
      expect(asMessageLike.content, 'hey');
    });

    test('ConversationResponse.fromJson parses a nested OtherUser and null LastMessage', () {
      final conversation = ConversationResponse.fromJson({
        'Id': 'c1',
        'OtherUser': senderJson,
        'LastMessage': null,
        'LastMessageAt': null,
        'UnreadCount': 3,
      });
      expect(conversation.id, 'c1');
      expect(conversation.otherUser.username, 'huseyn');
      expect(conversation.lastMessage, isNull);
      expect(conversation.unreadCount, 3);
    });
  });

  test('DirectMessageDeletedEvent/ConversationReadEvent parse the camelCase DirectMessagesHub payload', () {
    final deleted = DirectMessageDeletedEvent.fromJson({'conversationId': 'c1', 'messageId': 'm1'});
    expect(deleted.conversationId, 'c1');
    expect(deleted.messageId, 'm1');

    final read = ConversationReadEvent.fromJson({
      'conversationId': 'c1',
      'userId': 'u1',
      'readAt': '2026-01-01T00:00:00Z',
    });
    expect(read.conversationId, 'c1');
    expect(read.userId, 'u1');
    expect(read.readAt, DateTime.parse('2026-01-01T00:00:00Z'));
  });

  test('ApiConfig has no trailing slash and builds expected URLs', () {
    expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    expect(ApiConfig.restBaseUrl, '${ApiConfig.baseUrl}/Api/V1.0');
    expect(ApiConfig.hubsBaseUrl, '${ApiConfig.baseUrl}/hubs');
  });
}
