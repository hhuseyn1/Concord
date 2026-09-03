import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'paged_list_controller.dart';

final friendsListControllerProvider =
    StateNotifierProvider.autoDispose<PagedListController<PublicProfileResponse>, PagedListState<PublicProfileResponse>>(
  (ref) {
    final service = ref.watch(friendsServiceProvider);
    return PagedListController<PublicProfileResponse>(
      ({required int page, required int pageSize}) => service.listFriends(page: page, pageSize: pageSize),
    );
  },
);

final blockedListControllerProvider =
    StateNotifierProvider.autoDispose<PagedListController<PublicProfileResponse>, PagedListState<PublicProfileResponse>>(
  (ref) {
    final service = ref.watch(friendsServiceProvider);
    return PagedListController<PublicProfileResponse>(
      ({required int page, required int pageSize}) => service.listBlocked(page: page, pageSize: pageSize),
    );
  },
);

final incomingRequestsProvider = FutureProvider.autoDispose<List<FriendRequestSummary>>((ref) {
  return ref.watch(friendsServiceProvider).incomingRequests();
});

final outgoingRequestsProvider = FutureProvider.autoDispose<List<FriendRequestSummary>>((ref) {
  return ref.watch(friendsServiceProvider).outgoingRequests();
});

void invalidateFriendsState(WidgetRef ref) {
  ref.invalidate(incomingRequestsProvider);
  ref.invalidate(outgoingRequestsProvider);
  ref.invalidate(friendsListControllerProvider);
  ref.invalidate(blockedListControllerProvider);
}
