import 'json_utils.dart';

class RecoveryCodesResponse {
  const RecoveryCodesResponse({required this.codes});

  factory RecoveryCodesResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryCodesResponse(codes: parseStringList(json.field('Codes')));
  }

  final List<String> codes;
}
