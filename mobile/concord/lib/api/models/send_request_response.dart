import 'enums.dart';
import 'json_utils.dart';

class SendRequestResponse {
  const SendRequestResponse({required this.requestId, required this.status});

  factory SendRequestResponse.fromJson(Map<String, dynamic> json) {
    return SendRequestResponse(
      requestId: json.field('RequestId') as String,
      status: FriendRequestStatus.fromWire(json.field('Status')),
    );
  }

  final String requestId;
  final FriendRequestStatus status;
}
