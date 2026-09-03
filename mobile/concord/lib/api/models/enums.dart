library;

/// Mirrors `Concord.Application.Enums.PresenceStatus`.
/// `Online = 0`, `Idle = 1`, `DoNotDisturb = 2`, `Invisible = 3`, `Offline = 4`.
enum PresenceStatus {
  online,
  idle,
  doNotDisturb,
  invisible,
  offline;

  int toWire() => index;

  static PresenceStatus fromWire(dynamic value) {
    if (value is int && value >= 0 && value < PresenceStatus.values.length) {
      return PresenceStatus.values[value];
    }
    if (value is String) {
      return PresenceStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => PresenceStatus.offline,
      );
    }
    return PresenceStatus.offline;
  }
}

/// Mirrors `Concord.Application.Enums.ChannelType`.
/// `Text = 0`, `Voice = 1`.
enum ChannelType {
  text,
  voice;

  int toWire() => index;

  static ChannelType fromWire(dynamic value) {
    if (value is int && value >= 0 && value < ChannelType.values.length) {
      return ChannelType.values[value];
    }
    if (value is String) {
      return ChannelType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ChannelType.text,
      );
    }
    return ChannelType.text;
  }
}

/// Mirrors `Concord.Application.Enums.FriendRequestStatus`.
/// `Pending = 0`, `Accepted = 1`.
enum FriendRequestStatus {
  pending,
  accepted;

  int toWire() => index;

  static FriendRequestStatus fromWire(dynamic value) {
    if (value is int && value >= 0 && value < FriendRequestStatus.values.length) {
      return FriendRequestStatus.values[value];
    }
    if (value is String) {
      return FriendRequestStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => FriendRequestStatus.pending,
      );
    }
    return FriendRequestStatus.pending;
  }
}

/// Mirrors `Concord.Application.Enums.NotificationType`.
/// `FriendRequestReceived = 0`, `FriendRequestAccepted = 1`, `MissedCall = 2`,
/// `Mention = 3`, `FriendRequestDeclined = 4`, `FriendRequestCancelled = 5`.
enum NotificationType {
  friendRequestReceived,
  friendRequestAccepted,
  missedCall,
  mention,
  friendRequestDeclined,
  friendRequestCancelled;

  int toWire() => index;

  static NotificationType fromWire(dynamic value) {
    if (value is int && value >= 0 && value < NotificationType.values.length) {
      return NotificationType.values[value];
    }
    if (value is String) {
      return NotificationType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => NotificationType.friendRequestReceived,
      );
    }
    return NotificationType.friendRequestReceived;
  }
}

/// Mirrors `Concord.Application.Enums.FriendRequestPrivacy`.
/// `Everyone = 0`, `FriendsOfFriends = 1`, `Nobody = 2`.
enum FriendRequestPrivacy {
  everyone,
  friendsOfFriends,
  nobody;

  int toWire() => index;

  static FriendRequestPrivacy fromWire(dynamic value) {
    if (value is int && value >= 0 && value < FriendRequestPrivacy.values.length) {
      return FriendRequestPrivacy.values[value];
    }
    if (value is String) {
      return FriendRequestPrivacy.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => FriendRequestPrivacy.everyone,
      );
    }
    return FriendRequestPrivacy.everyone;
  }
}

/// Mirrors `Concord.Application.Enums.DirectMessagePrivacy`.
/// `Everyone = 0`, `FriendsOnly = 1`, `Nobody = 2`.
enum DirectMessagePrivacy {
  everyone,
  friendsOnly,
  nobody;

  int toWire() => index;

  static DirectMessagePrivacy fromWire(dynamic value) {
    if (value is int && value >= 0 && value < DirectMessagePrivacy.values.length) {
      return DirectMessagePrivacy.values[value];
    }
    if (value is String) {
      return DirectMessagePrivacy.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => DirectMessagePrivacy.everyone,
      );
    }
    return DirectMessagePrivacy.everyone;
  }
}

/// Mirrors `Concord.Application.Enums.ActivityVisibility`.
/// `Everyone = 0`, `FriendsOnly = 1`, `Nobody = 2`.
enum ActivityVisibility {
  everyone,
  friendsOnly,
  nobody;

  int toWire() => index;

  static ActivityVisibility fromWire(dynamic value) {
    if (value is int && value >= 0 && value < ActivityVisibility.values.length) {
      return ActivityVisibility.values[value];
    }
    if (value is String) {
      return ActivityVisibility.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ActivityVisibility.everyone,
      );
    }
    return ActivityVisibility.everyone;
  }
}

/// Mirrors `Concord.Application.Enums.ActivityType`.
/// `Playing = 0`, `Listening = 1`, `Coding = 2`, `Using = 3`.
enum ActivityType {
  playing,
  listening,
  coding,
  using;

  int toWire() => index;

  static ActivityType fromWire(dynamic value) {
    if (value is int && value >= 0 && value < ActivityType.values.length) {
      return ActivityType.values[value];
    }
    if (value is String) {
      return ActivityType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ActivityType.playing,
      );
    }
    return ActivityType.playing;
  }
}

/// Mirrors `Concord.Application.Enums.CallType`. `Voice = 0`, `Video = 1`.
enum CallType {
  voice,
  video;

  int toWire() => index;

  static CallType fromWire(dynamic value) {
    if (value is int && value >= 0 && value < CallType.values.length) {
      return CallType.values[value];
    }
    if (value is String) {
      return CallType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => CallType.voice,
      );
    }
    return CallType.voice;
  }
}

/// Mirrors `Concord.Application.Enums.CallStatus`.
/// `Ringing = 0`, `Accepted = 1`, `Declined = 2`, `Missed = 3`, `Ended = 4`.
enum CallStatus {
  ringing,
  accepted,
  declined,
  missed,
  ended;

  static CallStatus fromWire(dynamic value) {
    if (value is int && value >= 0 && value < CallStatus.values.length) {
      return CallStatus.values[value];
    }
    if (value is String) {
      return CallStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => CallStatus.ended,
      );
    }
    return CallStatus.ended;
  }
}

/// Mirrors `Concord.Application.Enums.MessageSourceType` — discriminates a
/// `GlobalSearchResultResponse` row. `Channel = 0`, `DirectMessage = 1`.
enum MessageSourceType {
  channel,
  directMessage;

  static MessageSourceType fromWire(dynamic value) {
    if (value is int && value >= 0 && value < MessageSourceType.values.length) {
      return MessageSourceType.values[value];
    }
    if (value is String) {
      return MessageSourceType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => MessageSourceType.channel,
      );
    }
    return MessageSourceType.channel;
  }
}

/// Mirrors `Concord.Application.Enums.CustomStatusExpiryPreset`.
/// `Never = 0`, `ThirtyMinutes = 1`, `OneHour = 2`, `FourHours = 3`, `Today = 4`.
enum CustomStatusExpiryPreset {
  never,
  thirtyMinutes,
  oneHour,
  fourHours,
  today;

  int toWire() => index;

  static CustomStatusExpiryPreset fromWire(dynamic value) {
    if (value is int && value >= 0 && value < CustomStatusExpiryPreset.values.length) {
      return CustomStatusExpiryPreset.values[value];
    }
    if (value is String) {
      return CustomStatusExpiryPreset.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => CustomStatusExpiryPreset.never,
      );
    }
    return CustomStatusExpiryPreset.never;
  }
}

/// Mirrors `Concord.Application.Enums.FriendRelationshipStatus`.
/// `None = 0`, `Friends = 1`, `OutgoingRequest = 2`, `IncomingRequest = 3`,
/// `Blocked = 4`.
enum FriendRelationshipStatus {
  none,
  friends,
  outgoingRequest,
  incomingRequest,
  blocked;

  int toWire() => index;

  static FriendRelationshipStatus fromWire(dynamic value) {
    if (value is int && value >= 0 && value < FriendRelationshipStatus.values.length) {
      return FriendRelationshipStatus.values[value];
    }
    if (value is String) {
      return FriendRelationshipStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => FriendRelationshipStatus.none,
      );
    }
    return FriendRelationshipStatus.none;
  }
}
