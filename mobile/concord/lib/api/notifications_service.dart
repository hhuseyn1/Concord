import 'api_client.dart';
import 'models/notification_response.dart';
import 'models/paged_result.dart';

class NotificationsService {
  NotificationsService(this._client);

  final ApiClient _client;

  Future<PagedResult<NotificationResponse>> list({int page = 1, int pageSize = 30}) async {
    final data = await _client.get('/Notifications', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, NotificationResponse.fromJson);
  }

  Future<void> markRead(String notificationId) => _client.post('/Notifications/$notificationId:Read');

  Future<void> markAllRead() => _client.post('/Notifications/Read');
}
