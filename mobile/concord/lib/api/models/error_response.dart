import 'json_utils.dart';

class ErrorResponse {
  const ErrorResponse({required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(message: json.field('Message') as String? ?? '');
  }

  final String message;
}
