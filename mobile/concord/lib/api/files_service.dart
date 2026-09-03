import 'dart:typed_data';

import 'api_client.dart';
import 'models/file_upload_response.dart';

class FilesService {
  FilesService(this._client);

  final ApiClient _client;

  Future<FileUploadResponse> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final data = await _client.postMultipart(
      '/Files/Avatar',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return FileUploadResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<FileUploadResponse> uploadServerIcon({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final data = await _client.postMultipart(
      '/Files/ServerIcon',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return FileUploadResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<FileUploadResponse> uploadAttachment({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final data = await _client.postMultipart(
      '/Files/Attachment',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return FileUploadResponse.fromJson(data as Map<String, dynamic>);
  }
}
