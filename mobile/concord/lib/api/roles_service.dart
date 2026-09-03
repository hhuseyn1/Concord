import 'api_client.dart';
import 'models/my_server_permissions_response.dart';

class RolesService {
  RolesService(this._client);

  final ApiClient _client;

  Future<MyServerPermissionsResponse> getMyPermissions(String serverId) async {
    final data = await _client.get('/Servers/$serverId/Roles/Me');
    return MyServerPermissionsResponse.fromJson(data as Map<String, dynamic>);
  }
}
