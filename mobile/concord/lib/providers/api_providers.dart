import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'auth_controller.dart';


final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).handleSessionExpired(),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref.watch(apiClientProvider));
});

final serversServiceProvider = Provider<ServersService>((ref) {
  return ServersService(ref.watch(apiClientProvider));
});

final channelsServiceProvider = Provider<ChannelsService>((ref) {
  return ChannelsService(ref.watch(apiClientProvider));
});

final messagesServiceProvider = Provider<MessagesService>((ref) {
  return MessagesService(ref.watch(apiClientProvider));
});

final filesServiceProvider = Provider<FilesService>((ref) {
  return FilesService(ref.watch(apiClientProvider));
});

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(ref.watch(apiClientProvider));
});

final directMessagesServiceProvider = Provider<DirectMessagesService>((ref) {
  return DirectMessagesService(ref.watch(apiClientProvider));
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(ref.watch(apiClientProvider));
});

final directVoiceServiceProvider = Provider<DirectVoiceService>((ref) {
  return DirectVoiceService(ref.watch(apiClientProvider));
});

final directCallsServiceProvider = Provider<DirectCallsService>((ref) {
  return DirectCallsService(ref.watch(apiClientProvider));
});

final sessionsServiceProvider = Provider<SessionsService>((ref) {
  return SessionsService(ref.watch(apiClientProvider));
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(apiClientProvider));
});

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService(ref.watch(apiClientProvider));
});

final rolesServiceProvider = Provider<RolesService>((ref) {
  return RolesService(ref.watch(apiClientProvider));
});

final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService(ref.watch(apiClientProvider));
});

final qrLoginServiceProvider = Provider<QrLoginService>((ref) {
  return QrLoginService(ref.watch(apiClientProvider));
});
