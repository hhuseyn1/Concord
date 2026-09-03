import 'json_utils.dart';

class FileUploadResponse {
  const FileUploadResponse({required this.url});

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(url: json.field('Url') as String);
  }

  final String url;
}
