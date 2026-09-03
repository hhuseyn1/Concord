import 'json_utils.dart';

/// Freshly generated recovery codes. Returned exactly once, at the moment they are created - only
/// their hashes are stored server-side, so this response cannot be reproduced later.
class RecoveryCodesResponse {
  const RecoveryCodesResponse({required this.codes});

  factory RecoveryCodesResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryCodesResponse(codes: parseStringList(json.field('Codes')));
  }

  final List<String> codes;
}
