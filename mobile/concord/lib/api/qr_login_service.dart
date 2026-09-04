import 'api_client.dart';
import 'models/qr_login_request_info_response.dart';

class QrLoginService {
  QrLoginService(this._client);

  final ApiClient _client;

  Future<QrLoginRequestInfoResponse> getRequestInfo(String userCode) async {
    final data = await _client.get('/QrLogin/Requests/${Uri.encodeComponent(userCode)}');
    return QrLoginRequestInfoResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> approve(String userCode) {
    return _client.post('/QrLogin/Requests/${Uri.encodeComponent(userCode)}/Approve');
  }

  Future<void> deny(String userCode) {
    return _client.post('/QrLogin/Requests/${Uri.encodeComponent(userCode)}/Deny');
  }
}
