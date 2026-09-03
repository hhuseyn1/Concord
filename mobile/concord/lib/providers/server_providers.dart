import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';

final myServersProvider = FutureProvider<List<ServerResponse>>((ref) {
  return ref.watch(serversServiceProvider).listServers();
});

final channelsProvider = FutureProvider.family<List<ChannelResponse>, String>((ref, serverId) {
  return ref.watch(channelsServiceProvider).listChannels(serverId);
});

final serverMembersProvider = FutureProvider.family<List<ServerMemberSummary>, String>((ref, serverId) async {
  final result = await ref.watch(serversServiceProvider).listMembers(serverId, page: 1, pageSize: 30);
  return result.items;
});

final myPermissionsProvider = FutureProvider.autoDispose.family<MyServerPermissionsResponse, String>((ref, serverId) {
  return ref.watch(rolesServiceProvider).getMyPermissions(serverId);
});
