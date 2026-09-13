import 'json_utils.dart';

class PortalSessionResponse {
  const PortalSessionResponse({required this.url});

  factory PortalSessionResponse.fromJson(Map<String, dynamic> json) {
    return PortalSessionResponse(url: json.field('Url') as String);
  }

  final String url;
}
