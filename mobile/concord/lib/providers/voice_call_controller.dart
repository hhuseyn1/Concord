import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../api/api.dart';
import 'api_providers.dart';
import 'auth_controller.dart';
import 'voice_call_state.dart';

class VoiceCallController extends StateNotifier<VoiceCallState> {
  VoiceCallController(this._ref) : super(const VoiceCallState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (isAuthenticated && !wasAuthenticated) {
        unawaited(_connectHubs());
      } else if (!isAuthenticated && wasAuthenticated) {
        unawaited(_teardownForSignOut());
      }
    }, fireImmediately: true);
  }

  static const _ringTimeout = Duration(seconds: 45);

  final Ref _ref;

  VoiceHub? _voiceHub;
  DirectMessagesHub? _dmHub;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _roomListener;
  Timer? _ringTimer;
  final List<StreamSubscription<Object?>> _hubSubscriptions = [];

  VoiceService get _voiceService => _ref.read(voiceServiceProvider);
  DirectVoiceService get _directVoiceService => _ref.read(directVoiceServiceProvider);
  DirectCallsService get _directCallsService => _ref.read(directCallsServiceProvider);
  UsersService get _usersService => _ref.read(usersServiceProvider);

  Future<void> _connectHubs() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    final voiceHub = VoiceHub(tokenStorage: tokenStorage);
    final dmHub = DirectMessagesHub(tokenStorage: tokenStorage);
    _voiceHub = voiceHub;
    _dmHub = dmHub;

    _hubSubscriptions.addAll([
      voiceHub.onParticipantJoined.listen(_handleChannelParticipantJoined),
      voiceHub.onParticipantLeft.listen(_handleChannelParticipantLeft),
      dmHub.onCallParticipantJoined.listen(_handleDmParticipantJoined),
      dmHub.onCallParticipantLeft.listen(_handleDmParticipantLeft),
      dmHub.onCallInitiated.listen((call) => unawaited(_handleCallInitiated(call))),
      dmHub.onCallAccepted.listen(_handleCallAccepted),
      dmHub.onCallDeclined.listen(_handleCallDeclined),
      dmHub.onCallEnded.listen(_handleCallEnded),
    ]);

    try {
      await voiceHub.connect();
    } catch (_) {
    }
    try {
      await dmHub.connect();
    } catch (_) {}
  }

  Future<void> _teardownForSignOut() async {
    await _teardownConnections();
    if (mounted) state = const VoiceCallState();
  }

  Future<void> _teardownConnections() async {
    for (final subscription in _hubSubscriptions) {
      unawaited(subscription.cancel());
    }
    _hubSubscriptions.clear();
    final voiceHub = _voiceHub;
    final dmHub = _dmHub;
    _voiceHub = null;
    _dmHub = null;
    if (voiceHub != null) unawaited(voiceHub.dispose());
    if (dmHub != null) unawaited(dmHub.dispose());
    _ringTimer?.cancel();
    _ringTimer = null;
    final room = _room;
    _room = null;
    if (room != null) unawaited(room.disconnect());
    await _roomListener?.dispose();
    _roomListener = null;
  }


  Future<void> joinChannelCall(String serverId, String channelId) async {
    final current = state.activeCall;
    if (current?.kind == ActiveCallKind.channel && current?.channelId == channelId) return;
    if (current != null) await _leaveCallInternal();

    await _connectRoom(
      nextCall: ActiveCallInfo.channel(serverId: serverId, channelId: channelId),
      getToken: () => _voiceService.getToken(channelId),
      getParticipants: () => _voiceService.listParticipants(channelId),
      hubJoin: () => _voiceHub?.joinChannel(channelId) ?? Future<void>.value(),
    );
  }

  void _handleChannelParticipantJoined(VoiceParticipantEvent event) {
    final call = state.activeCall;
    if (call?.kind != ActiveCallKind.channel || call?.channelId != event.channelId) return;
    _upsertParticipant(event.userId);
  }

  void _handleChannelParticipantLeft(VoiceParticipantEvent event) {
    final call = state.activeCall;
    if (call?.kind != ActiveCallKind.channel || call?.channelId != event.channelId) return;
    _removeParticipant(event.userId);
  }


  Future<void> startDmCall(String conversationId, CallType type) async {
    if (state.activeCall != null) await _leaveCallInternal();
    if (state.outgoingCall != null || state.incomingCall != null) return;

    CallResponse call;
    try {
      call = await _directCallsService.startCall(conversationId, type);
    } on ApiException catch (e) {
      state = state.copyWith(lastError: "Couldn't start the call: ${e.message}");
      return;
    }

    state = state.copyWith(
      outgoingCall: OutgoingCall(callId: call.id, conversationId: conversationId, type: type),
      clearLastError: true,
    );
    _ringTimer?.cancel();
    _ringTimer = Timer(_ringTimeout, () {
      final outgoing = state.outgoingCall;
      if (outgoing?.callId != call.id) return;
      unawaited(_endCallSilently(conversationId, call.id));
      state = state.copyWith(clearOutgoingCall: true, lastError: 'No answer.');
    });
  }

  Future<void> acceptIncomingCall() async {
    final call = state.incomingCall;
    if (call == null) return;
    state = state.copyWith(clearIncomingCall: true);

    try {
      await _directCallsService.acceptCall(call.conversationId, call.callId);
    } on ApiException catch (e) {
      state = state.copyWith(lastError: "Couldn't accept the call: ${e.message}");
      return;
    }

    await _connectRoom(
      nextCall: ActiveCallInfo.dm(conversationId: call.conversationId, callId: call.callId),
      getToken: () => _directVoiceService.getToken(call.conversationId),
      getParticipants: () => _directVoiceService.listParticipants(call.conversationId),
      initialVideo: call.type == CallType.video,
    );
  }

  Future<void> declineIncomingCall() async {
    final call = state.incomingCall;
    if (call == null) return;
    state = state.copyWith(clearIncomingCall: true);
    try {
      await _directCallsService.declineCall(call.conversationId, call.callId);
    } on ApiException catch (_) {
    }
  }

  Future<void> cancelOutgoingCall() async {
    final call = state.outgoingCall;
    if (call == null) return;
    _ringTimer?.cancel();
    state = state.copyWith(clearOutgoingCall: true);
    try {
      await _directCallsService.endCall(call.conversationId, call.callId);
    } on ApiException catch (_) {}
  }

  Future<void> _handleCallInitiated(CallResponse call) async {
    String? callerName;
    String? callerAvatarUrl;
    try {
      final caller = await _usersService.getUser(call.initiatorId);
      callerName = caller.username?.isNotEmpty == true
          ? caller.username
          : [caller.name, caller.surname].where((part) => part != null && part.isNotEmpty).join(' ');
      callerAvatarUrl = caller.avatarUrl;
    } on ApiException catch (_) {
    }

    state = state.copyWith(
      incomingCall: IncomingCall(
        callId: call.id,
        conversationId: call.conversationId,
        callerId: call.initiatorId,
        type: call.type,
        callerName: callerName,
        callerAvatarUrl: callerAvatarUrl,
      ),
    );
  }

  void _handleCallAccepted(CallResponse call) {
    final outgoing = state.outgoingCall;
    if (outgoing?.callId != call.id) return;
    _ringTimer?.cancel();
    state = state.copyWith(clearOutgoingCall: true);
    unawaited(_connectRoom(
      nextCall: ActiveCallInfo.dm(conversationId: outgoing!.conversationId, callId: outgoing.callId),
      getToken: () => _directVoiceService.getToken(outgoing.conversationId),
      getParticipants: () => _directVoiceService.listParticipants(outgoing.conversationId),
      initialVideo: outgoing.type == CallType.video,
    ));
  }

  void _handleCallDeclined(CallResponse call) {
    final outgoing = state.outgoingCall;
    if (outgoing?.callId != call.id) return;
    _ringTimer?.cancel();
    state = state.copyWith(clearOutgoingCall: true, lastError: 'Call declined.');
  }

  void _handleCallEnded(CallResponse call) {
    if (state.incomingCall?.callId == call.id) {
      state = state.copyWith(clearIncomingCall: true);
    }
    if (state.outgoingCall?.callId == call.id) {
      _ringTimer?.cancel();
      state = state.copyWith(clearOutgoingCall: true);
    }
    final active = state.activeCall;
    if (active?.kind == ActiveCallKind.dm && active?.callId == call.id && _room != null) {
      unawaited(_leaveCallInternal());
    }
  }

  void _handleDmParticipantJoined(DirectCallParticipantEvent event) {
    final call = state.activeCall;
    if (call?.kind != ActiveCallKind.dm || call?.conversationId != event.conversationId) return;
    _upsertParticipant(event.userId);
  }

  void _handleDmParticipantLeft(DirectCallParticipantEvent event) {
    final call = state.activeCall;
    if (call?.kind != ActiveCallKind.dm || call?.conversationId != event.conversationId) return;
    _removeParticipant(event.userId);
  }


  Future<void> _connectRoom({
    required ActiveCallInfo nextCall,
    required Future<VoiceTokenResponse> Function() getToken,
    required Future<List<VoiceParticipantSummary>> Function() getParticipants,
    Future<void> Function()? hubJoin,
    bool initialVideo = false,
  }) async {
    state = state.copyWith(isConnecting: true, clearLastError: true);

    VoiceTokenResponse token;
    try {
      token = await getToken();
    } on ApiException catch (e) {
      state = state.copyWith(isConnecting: false, lastError: "Couldn't join the call: ${e.message}");
      return;
    }

    final room = lk.Room();
    final listener = room.createListener();

    listener.on<lk.RoomDisconnectedEvent>((event) {
      if (!mounted || _room != room) return;
      final wasIntentional = event.reason == null || event.reason == lk.DisconnectReason.clientInitiated;
      _resetCallState();
      if (!wasIntentional) {
        state = state.copyWith(lastError: 'Call ended unexpectedly - check your connection.');
      }
    });
    listener.on<lk.RoomReconnectingEvent>((_) {
      if (mounted) state = state.copyWith(isReconnecting: true);
    });
    listener.on<lk.RoomReconnectedEvent>((_) {
      if (mounted) state = state.copyWith(isReconnecting: false);
    });
    listener.on<lk.ActiveSpeakersChangedEvent>((event) {
      if (mounted) state = state.copyWith(activeSpeakerIds: event.speakers.map((p) => p.identity).toSet());
    });
    listener.on<lk.ParticipantConnectedEvent>((event) {
      if (mounted) _upsertParticipant(event.participant.identity);
    });
    listener.on<lk.ParticipantDisconnectedEvent>((event) {
      if (mounted) _removeParticipant(event.participant.identity);
    });
    listener.on<lk.TrackSubscribedEvent>((event) {
      if (mounted && state.isDeafened && event.track.kind == lk.TrackType.AUDIO) {
        unawaited(event.track.disable());
      }
    });

    try {
      await room.connect(token.url, token.token);
    } catch (e) {
      await listener.dispose();
      if (mounted) state = state.copyWith(isConnecting: false, lastError: "Couldn't connect to the call.");
      return;
    }

    if (!mounted) {
      unawaited(room.disconnect());
      await listener.dispose();
      return;
    }

    _room = room;
    _roomListener = listener;

    try {
      await room.localParticipant?.setMicrophoneEnabled(true);
    } catch (_) {
    }

    var videoEnabled = false;
    if (initialVideo) {
      try {
        await room.localParticipant?.setCameraEnabled(true);
        videoEnabled = true;
      } catch (_) {}
    }

    if (hubJoin != null) {
      unawaited(hubJoin());
    }

    final seeded = Map<String, CallParticipant>.of(state.participants);
    try {
      final list = await getParticipants();
      for (final item in list) {
        seeded.putIfAbsent(item.userId, () => CallParticipant(userId: item.userId, joinedAt: item.joinedAt));
      }
    } catch (_) {
    }

    if (!mounted) return;
    state = state.copyWith(
      activeCall: nextCall,
      room: room,
      participants: seeded,
      isConnecting: false,
      isVideoEnabled: videoEnabled,
    );
  }

  Future<void> leaveCall() async {
    if (state.activeCall == null) return;
    await _leaveCallInternal();
  }

  Future<void> _leaveCallInternal() async {
    final call = state.activeCall;
    final room = _room;
    _room = null;
    final listener = _roomListener;
    _roomListener = null;

    if (room != null) {
      try {
        await room.disconnect();
      } catch (_) {}
    }
    await listener?.dispose();

    if (call?.kind == ActiveCallKind.channel && call?.channelId != null) {
      try {
        await _voiceHub?.leaveChannel(call!.channelId!);
      } catch (_) {}
    }
    if (call?.kind == ActiveCallKind.dm && call?.callId != null) {
      unawaited(_endCallSilently(call!.conversationId!, call.callId!));
    }

    _resetCallState();
  }

  Future<void> _endCallSilently(String conversationId, String callId) async {
    try {
      await _directCallsService.endCall(conversationId, callId);
    } on ApiException catch (_) {
    }
  }

  void _resetCallState() {
    state = state.copyWith(
      clearActiveCall: true,
      clearRoom: true,
      participants: const {},
      isConnecting: false,
      isMuted: false,
      isDeafened: false,
      isVideoEnabled: false,
      isReconnecting: false,
      activeSpeakerIds: const {},
    );
  }

  void _upsertParticipant(String userId) {
    if (state.participants.containsKey(userId)) return;
    state = state.copyWith(participants: {
      ...state.participants,
      userId: CallParticipant(userId: userId, joinedAt: DateTime.now()),
    });
  }

  void _removeParticipant(String userId) {
    if (!state.participants.containsKey(userId)) return;
    final next = Map<String, CallParticipant>.of(state.participants)..remove(userId);
    state = state.copyWith(participants: next);
  }


  Future<void> toggleMute() async {
    final next = !state.isMuted;
    state = state.copyWith(isMuted: next);
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!next);
    } catch (_) {
      state = state.copyWith(isMuted: !next);
    }
  }

  Future<void> toggleDeafen() async {
    final next = !state.isDeafened;
    state = state.copyWith(isDeafened: next);
    final room = _room;
    if (room == null) return;
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        try {
          if (next) {
            await track.disable();
          } else {
            await track.enable();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> toggleVideo() async {
    final next = !state.isVideoEnabled;
    try {
      await _room?.localParticipant?.setCameraEnabled(next);
      state = state.copyWith(isVideoEnabled: next);
    } catch (_) {}
  }

  void dismissError() {
    if (state.lastError == null) return;
    state = state.copyWith(clearLastError: true);
  }

  @override
  void dispose() {
    unawaited(_teardownConnections());
    super.dispose();
  }
}

final voiceCallControllerProvider = StateNotifierProvider<VoiceCallController, VoiceCallState>((ref) {
  return VoiceCallController(ref);
});
