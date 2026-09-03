import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../theme/theme.dart';
import 'api_providers.dart';

final userProfileProvider = FutureProvider.family<PublicProfileResponse, String>((ref, userId) {
  return ref.watch(usersServiceProvider).getUser(userId);
});

String displayNameFor(PublicProfileResponse? profile, {String fallback = 'Unknown user'}) {
  if (profile == null) return fallback;
  if (profile.username != null && profile.username!.isNotEmpty) return profile.username!;
  final fullName = [profile.name, profile.surname].where((p) => p != null && p.isNotEmpty).join(' ');
  return fullName.isNotEmpty ? fullName : fallback;
}

ConcordPresence concordPresenceFor(PresenceStatus status) {
  return switch (status) {
    PresenceStatus.online => ConcordPresence.online,
    PresenceStatus.idle => ConcordPresence.idle,
    PresenceStatus.doNotDisturb => ConcordPresence.dnd,
    PresenceStatus.invisible => ConcordPresence.offline,
    PresenceStatus.offline => ConcordPresence.offline,
  };
}

int presenceSortWeight(PresenceStatus status) {
  return switch (status) {
    PresenceStatus.online => 0,
    PresenceStatus.idle => 1,
    PresenceStatus.doNotDisturb => 2,
    PresenceStatus.invisible => 3,
    PresenceStatus.offline => 3,
  };
}
