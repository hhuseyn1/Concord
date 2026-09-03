import 'package:livekit_client/livekit_client.dart' show Room;

import '../api/models/enums.dart';

enum ActiveCallKind { channel, dm }

class ActiveCallInfo {
  const ActiveCallInfo.channel({required this.serverId, required this.channelId})
      : kind = ActiveCallKind.channel,
        conversationId = null,
        callId = null;

  const ActiveCallInfo.dm({required this.conversationId, this.callId})
      : kind = ActiveCallKind.dm,
        serverId = null,
        channelId = null;

  final ActiveCallKind kind;
  final String? serverId;
  final String? channelId;
  final String? conversationId;
  final String? callId;

  ActiveCallInfo withCallId(String callId) {
    return ActiveCallInfo.dm(conversationId: conversationId, callId: callId);
  }
}

class CallParticipant {
  const CallParticipant({required this.userId, this.joinedAt});

  final String userId;
  final DateTime? joinedAt;
}

class IncomingCall {
  const IncomingCall({
    required this.callId,
    required this.conversationId,
    required this.callerId,
    required this.type,
    this.callerName,
    this.callerAvatarUrl,
  });

  final String callId;
  final String conversationId;
  final String callerId;
  final CallType type;
  final String? callerName;
  final String? callerAvatarUrl;
}

class OutgoingCall {
  const OutgoingCall({required this.callId, required this.conversationId, required this.type});

  final String callId;
  final String conversationId;
  final CallType type;
}

class VoiceCallState {
  const VoiceCallState({
    this.activeCall,
    this.room,
    this.participants = const {},
    this.isConnecting = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.isVideoEnabled = false,
    this.isReconnecting = false,
    this.activeSpeakerIds = const {},
    this.incomingCall,
    this.outgoingCall,
    this.lastError,
  });

  final ActiveCallInfo? activeCall;

  final Room? room;

  final Map<String, CallParticipant> participants;
  final bool isConnecting;
  final bool isMuted;
  final bool isDeafened;
  final bool isVideoEnabled;
  final bool isReconnecting;
  final Set<String> activeSpeakerIds;
  final IncomingCall? incomingCall;
  final OutgoingCall? outgoingCall;

  final String? lastError;

  bool get isInCall => activeCall != null;

  VoiceCallState copyWith({
    ActiveCallInfo? activeCall,
    bool clearActiveCall = false,
    Room? room,
    bool clearRoom = false,
    Map<String, CallParticipant>? participants,
    bool? isConnecting,
    bool? isMuted,
    bool? isDeafened,
    bool? isVideoEnabled,
    bool? isReconnecting,
    Set<String>? activeSpeakerIds,
    IncomingCall? incomingCall,
    bool clearIncomingCall = false,
    OutgoingCall? outgoingCall,
    bool clearOutgoingCall = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return VoiceCallState(
      activeCall: clearActiveCall ? null : (activeCall ?? this.activeCall),
      room: clearRoom ? null : (room ?? this.room),
      participants: participants ?? this.participants,
      isConnecting: isConnecting ?? this.isConnecting,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      activeSpeakerIds: activeSpeakerIds ?? this.activeSpeakerIds,
      incomingCall: clearIncomingCall ? null : (incomingCall ?? this.incomingCall),
      outgoingCall: clearOutgoingCall ? null : (outgoingCall ?? this.outgoingCall),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}
