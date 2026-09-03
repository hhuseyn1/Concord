import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<GlobalSearchResultResponse> results;
  final bool isLoading;
  final String? error;

  SearchState copyWith({
    String? query,
    List<GlobalSearchResultResponse>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._ref) : super(const SearchState());

  static const _minQueryLength = 2;
  static const _debounce = Duration(milliseconds: 350);
  static const _pageSize = 20;

  final Ref _ref;
  Timer? _debounceTimer;
  int _requestId = 0;

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < _minQueryLength) {
      state = state.copyWith(results: const [], isLoading: false, clearError: true);
      return;
    }
    _debounceTimer = Timer(_debounce, () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ref
          .read(searchServiceProvider)
          .searchMessages(query, page: 1, pageSize: _pageSize);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(results: result.items, isLoading: false);
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchControllerProvider = StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController(ref);
});
