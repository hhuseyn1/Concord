import 'dart:async';

import '../models/call_response.dart';
import '../models/direct_message_response.dart';
import 'hub_base.dart';
import 'hub_events.dart';

class DirectMessagesHub extends ConcordHub {
  DirectMessagesHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/direct-messages') {
    connection.on('DirectMessageReceived', (args) {
      _messageReceived.add(DirectMessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectMessageEdited', (args) {
      _messageEdited.add(DirectMessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectMessageDeleted', (args) {
      _messageDeleted.add(DirectMessageDeletedEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectMessageReactionsChanged', (args) {
      _messageReactionsChanged.add(DirectMessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectMessagePinned', (args) {
      _messagePinned.add(DirectMessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectMessageUnpinned', (args) {
      _messageUnpinned.add(DirectMessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('ConversationRead', (args) {
      _conversationRead.add(ConversationReadEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('UserTyping', (args) {
      _userTyping.add(DirectMessageTypingEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('UserStoppedTyping', (args) {
      _userStoppedTyping.add(DirectMessageTypingEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallParticipantJoined', (args) {
      _callParticipantJoined.add(DirectCallParticipantEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallParticipantLeft', (args) {
      _callParticipantLeft.add(DirectCallParticipantEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallInitiated', (args) {
      _callInitiated.add(CallResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallAccepted', (args) {
      _callAccepted.add(CallResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallDeclined', (args) {
      _callDeclined.add(CallResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('DirectCallEnded', (args) {
      _callEnded.add(CallResponse.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _messageReceived = StreamController<DirectMessageResponse>.broadcast();
  final _messageEdited = StreamController<DirectMessageResponse>.broadcast();
  final _messageDeleted = StreamController<DirectMessageDeletedEvent>.broadcast();
  final _messageReactionsChanged = StreamController<DirectMessageResponse>.broadcast();
  final _messagePinned = StreamController<DirectMessageResponse>.broadcast();
  final _messageUnpinned = StreamController<DirectMessageResponse>.broadcast();
  final _conversationRead = StreamController<ConversationReadEvent>.broadcast();
  final _userTyping = StreamController<DirectMessageTypingEvent>.broadcast();
  final _userStoppedTyping = StreamController<DirectMessageTypingEvent>.broadcast();
  final _callParticipantJoined = StreamController<DirectCallParticipantEvent>.broadcast();
  final _callParticipantLeft = StreamController<DirectCallParticipantEvent>.broadcast();
  final _callInitiated = StreamController<CallResponse>.broadcast();
  final _callAccepted = StreamController<CallResponse>.broadcast();
  final _callDeclined = StreamController<CallResponse>.broadcast();
  final _callEnded = StreamController<CallResponse>.broadcast();

  Stream<DirectMessageResponse> get onMessageReceived => _messageReceived.stream;

  Stream<DirectMessageResponse> get onMessageEdited => _messageEdited.stream;

  Stream<DirectMessageDeletedEvent> get onMessageDeleted => _messageDeleted.stream;

  Stream<DirectMessageResponse> get onMessageReactionsChanged => _messageReactionsChanged.stream;

  Stream<DirectMessageResponse> get onMessagePinned => _messagePinned.stream;

  Stream<DirectMessageResponse> get onMessageUnpinned => _messageUnpinned.stream;

  Stream<ConversationReadEvent> get onConversationRead => _conversationRead.stream;

  Stream<DirectMessageTypingEvent> get onUserTyping => _userTyping.stream;

  Stream<DirectMessageTypingEvent> get onUserStoppedTyping => _userStoppedTyping.stream;

  Stream<DirectCallParticipantEvent> get onCallParticipantJoined => _callParticipantJoined.stream;

  Stream<DirectCallParticipantEvent> get onCallParticipantLeft => _callParticipantLeft.stream;

  Stream<CallResponse> get onCallInitiated => _callInitiated.stream;

  Stream<CallResponse> get onCallAccepted => _callAccepted.stream;

  Stream<CallResponse> get onCallDeclined => _callDeclined.stream;

  Stream<CallResponse> get onCallEnded => _callEnded.stream;

  Future<void> notifyTyping(String conversationId) => connection.invoke('Typing', args: [conversationId]);

  Future<void> stopTyping(String conversationId) => connection.invoke('StopTyping', args: [conversationId]);

  Future<void> dispose() async {
    await connection.stop();
    await _messageReceived.close();
    await _messageEdited.close();
    await _messageDeleted.close();
    await _messageReactionsChanged.close();
    await _messagePinned.close();
    await _messageUnpinned.close();
    await _conversationRead.close();
    await _userTyping.close();
    await _userStoppedTyping.close();
    await _callParticipantJoined.close();
    await _callParticipantLeft.close();
    await _callInitiated.close();
    await _callAccepted.close();
    await _callDeclined.close();
    await _callEnded.close();
  }
}
