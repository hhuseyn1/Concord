import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'paged_list_controller.dart';

final serverMemberListControllerProvider = StateNotifierProvider.autoDispose
    .family<PagedListController<ServerMemberSummary>, PagedListState<ServerMemberSummary>, String>(
  (ref, serverId) {
    final service = ref.watch(serversServiceProvider);
    return PagedListController<ServerMemberSummary>(
      ({required int page, required int pageSize}) =>
          service.listMembers(serverId, page: page, pageSize: pageSize),
    );
  },
);
