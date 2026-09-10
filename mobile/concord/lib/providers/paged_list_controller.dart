import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';

class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadError,
    this.page = 0,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadError;
  final int page;

  PagedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? loadError,
    bool clearLoadError = false,
    int? page,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      page: page ?? this.page,
    );
  }
}

typedef PageFetcher<T> = Future<PagedResult<T>> Function({required int page, required int pageSize});

class PagedListController<T> extends StateNotifier<PagedListState<T>> {
  // Not `const PagedListState()`: a bare `const` call here can't see this constructor's own `T`,
  // so Dart freezes it as `PagedListState<Never>` - the first real `copyWith(items: <T>...)` then
  // fails a runtime type check trying to put actual items into a list typed as `Never`. Writing the
  // type argument explicitly forces it through instead of leaving it for const inference to guess.
  PagedListController(this._fetchPage, {this.pageSize = 30}) : super(PagedListState<T>()) {
    unawaited(loadInitial());
  }

  final PageFetcher<T> _fetchPage;
  final int pageSize;
  bool _disposed = false;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final result = await _fetchPage(page: 1, pageSize: pageSize);
      if (_disposed) return;
      state = state.copyWith(items: result.items, isLoading: false, hasMore: result.hasNextPage, page: 1);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e.message);
    }
  }

  Future<void> retryInitialLoad() => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    try {
      final result = await _fetchPage(page: nextPage, pageSize: pageSize);
      if (_disposed) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        page: nextPage,
      );
    } on ApiException {
      if (_disposed) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void patchWhere(bool Function(T item) match, T Function(T item) update) {
    if (!state.items.any(match)) return;
    state = state.copyWith(items: [for (final item in state.items) if (match(item)) update(item) else item]);
  }

  void removeWhere(bool Function(T item) match) {
    if (!state.items.any(match)) return;
    state = state.copyWith(items: state.items.where((item) => !match(item)).toList());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
