import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'api_providers.dart';

class SessionsListState {
  const SessionsListState({this.items = const [], this.isLoading = true, this.loadError, this.revokingId});

  final List<SessionResponse> items;
  final bool isLoading;
  final ApiException? loadError;

  final String? revokingId;

  SessionsListState copyWith({
    List<SessionResponse>? items,
    bool? isLoading,
    ApiException? loadError,
    bool clearLoadError = false,
    String? revokingId,
    bool clearRevokingId = false,
  }) {
    return SessionsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      revokingId: clearRevokingId ? null : (revokingId ?? this.revokingId),
    );
  }
}

const revokeAllOthersMarker = '*others*';

class SessionsController extends StateNotifier<SessionsListState> {
  SessionsController(this._ref) : super(const SessionsListState()) {
    unawaited(load());
  }

  final Ref _ref;
  bool _disposed = false;

  SessionsService get _service => _ref.read(sessionsServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final sessions = await _service.getMySessions();
      if (_disposed) return;
      state = state.copyWith(items: sessions, isLoading: false);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e);
    }
  }

  Future<ApiException?> revoke(String sessionId) async {
    state = state.copyWith(revokingId: sessionId);
    try {
      await _service.revokeSession(sessionId);
      if (_disposed) return null;
      state = state.copyWith(
        items: state.items.where((s) => s.id != sessionId).toList(),
        clearRevokingId: true,
      );
      return null;
    } on ApiException catch (e) {
      if (!_disposed) state = state.copyWith(clearRevokingId: true);
      return e;
    }
  }

  Future<ApiException?> revokeAllOthers() async {
    state = state.copyWith(revokingId: revokeAllOthersMarker);
    try {
      await _service.revokeOtherSessions();
      if (_disposed) return null;
      state = state.copyWith(
        items: state.items.where((s) => s.isCurrent).toList(),
        clearRevokingId: true,
      );
      return null;
    } on ApiException catch (e) {
      if (!_disposed) state = state.copyWith(clearRevokingId: true);
      return e;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final sessionsControllerProvider = StateNotifierProvider.autoDispose<SessionsController, SessionsListState>((ref) {
  return SessionsController(ref);
});
