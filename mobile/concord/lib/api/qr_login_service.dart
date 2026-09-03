import 'api_client.dart';
import 'models/qr_login_request_info_response.dart';

/// `QrLoginController` (base route `Api/V1.0/QrLogin`) — cross-device sign-in, shaped like the OAuth
/// device authorization grant.
///
/// This app only ever plays the *approving* role: a browser with no session shows a QR / user code,
/// and this already-signed-in phone scans or types it, inspects the requesting device, and approves
/// or denies. Mobile never needs to start a session of its own via QR (it signs in directly), so the
/// unauthenticated `Sessions`/`Sessions/Status` endpoints used by the web QR-generating side are
/// deliberately not mirrored here.
class QrLoginService {
  QrLoginService(this._client);

  final ApiClient _client;

  /// Details of the device asking to sign in, for the approval screen. Requires authentication - the
  /// code alone must not reveal where a sign-in attempt is coming from.
  Future<QrLoginRequestInfoResponse> getRequestInfo(String userCode) async {
    final data = await _client.get('/QrLogin/Requests/${Uri.encodeComponent(userCode)}');
    return QrLoginRequestInfoResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Approves a request, signing the other device in as the calling user.
  Future<void> approve(String userCode) {
    return _client.post('/QrLogin/Requests/${Uri.encodeComponent(userCode)}/Approve');
  }

  /// Rejects a request. Terminal - the other device must start over.
  Future<void> deny(String userCode) {
    return _client.post('/QrLogin/Requests/${Uri.encodeComponent(userCode)}/Deny');
  }
}
