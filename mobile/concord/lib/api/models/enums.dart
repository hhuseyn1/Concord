library;

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
