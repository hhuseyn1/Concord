import 'dart:async';

import '../models/message_response.dart';
import 'hub_base.dart';
import 'hub_events.dart';

class MessagesHub extends ConcordHub {
  MessagesHub({required super.tokenStorage, super.baseUrl}) : super(hubPath: '/messages') {
    connection.on('MessageReceived', (args) {
      _messageReceived.add(MessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('MessageEdited', (args) {
      _messageEdited.add(MessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('MessageDeleted', (args) {
      _messageDeleted.add(args![0] as String);
    });
    connection.on('MessageReactionsChanged', (args) {
      _messageReactionsChanged.add(MessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('MessagePinned', (args) {
      _messagePinned.add(MessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('MessageUnpinned', (args) {
      _messageUnpinned.add(MessageResponse.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('UserTyping', (args) {
      _userTyping.add(TypingEvent.fromJson(args![0] as Map<String, dynamic>));
    });
    connection.on('UserStoppedTyping', (args) {
      _userStoppedTyping.add(TypingEvent.fromJson(args![0] as Map<String, dynamic>));
    });
  }

  final _messageReceived = StreamController<MessageResponse>.broadcast();
  final _messageEdited = StreamController<MessageResponse>.broadcast();
  final _messageDeleted = StreamController<String>.broadcast();
  final _messageReactionsChanged = StreamController<MessageResponse>.broadcast();
  final _messagePinned = StreamController<MessageResponse>.broadcast();
  final _messageUnpinned = StreamController<MessageResponse>.broadcast();
  final _userTyping = StreamController<TypingEvent>.broadcast();
  final _userStoppedTyping = StreamController<TypingEvent>.broadcast();

  Stream<MessageResponse> get onMessageReceived => _messageReceived.stream;

  Stream<MessageResponse> get onMessageEdited => _messageEdited.stream;

  Stream<String> get onMessageDeleted => _messageDeleted.stream;

  Stream<MessageResponse> get onMessageReactionsChanged => _messageReactionsChanged.stream;

  Stream<MessageResponse> get onMessagePinned => _messagePinned.stream;

  Stream<MessageResponse> get onMessageUnpinned => _messageUnpinned.stream;

  Stream<TypingEvent> get onUserTyping => _userTyping.stream;

  Stream<TypingEvent> get onUserStoppedTyping => _userStoppedTyping.stream;

  Future<void> joinChannel(String channelId) => connection.invoke('JoinChannel', args: [channelId]);

  Future<void> leaveChannel(String channelId) => connection.invoke('LeaveChannel', args: [channelId]);

  Future<void> notifyTyping(String channelId) => connection.invoke('Typing', args: [channelId]);

  Future<void> stopTyping(String channelId) => connection.invoke('StopTyping', args: [channelId]);

  Future<void> dispose() async {
    await connection.stop();
    await _messageReceived.close();
    await _messageEdited.close();
    await _messageDeleted.close();
    await _messageReactionsChanged.close();
    await _messagePinned.close();
    await _messageUnpinned.close();
    await _userTyping.close();
    await _userStoppedTyping.close();
  }
}
