import 'json_utils.dart';

class MyServerPermissionsResponse {
  const MyServerPermissionsResponse({
    required this.serverId,
    required this.isOwner,
    required this.permissionNames,
  });

  factory MyServerPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return MyServerPermissionsResponse(
      serverId: json.field('ServerId') as String,
      isOwner: json.field('IsOwner') as bool,
      permissionNames: parseStringList(json.field('PermissionNames')),
    );
  }

  final String serverId;
  final bool isOwner;
  final List<String> permissionNames;

  bool get hasManageMessages => isOwner || permissionNames.contains('ManageMessages');

  bool get hasManageChannels => isOwner || permissionNames.contains('ManageChannels');

  bool get hasManageInvites => isOwner || permissionNames.contains('ManageInvites');

  bool get hasKickMembers => isOwner || permissionNames.contains('KickMembers');

  bool get hasBanMembers => isOwner || permissionNames.contains('BanMembers');

  bool get hasMuteMembers => isOwner || permissionNames.contains('MuteMembers');

  bool get hasModerateMembers => isOwner || permissionNames.contains('ModerateMembers');

  bool get hasAnyModerationAction => hasMuteMembers || hasModerateMembers || hasKickMembers || hasBanMembers;
}
