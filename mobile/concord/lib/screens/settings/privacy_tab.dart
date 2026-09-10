import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../friends/blocked_tab.dart';

Map<FriendRequestPrivacy, String> _friendRequestLabels(AppLocalizations l10n) => {
      FriendRequestPrivacy.everyone: l10n.visibilityEveryone,
      FriendRequestPrivacy.friendsOfFriends: l10n.visibilityFriendsOfFriends,
      FriendRequestPrivacy.nobody: l10n.visibilityNobody,
    };

Map<DirectMessagePrivacy, String> _directMessageLabels(AppLocalizations l10n) => {
      DirectMessagePrivacy.everyone: l10n.visibilityEveryone,
      DirectMessagePrivacy.friendsOnly: l10n.visibilityFriendsOnly,
      DirectMessagePrivacy.nobody: l10n.visibilityNobody,
    };

Map<ActivityVisibility, String> _activityLabels(AppLocalizations l10n) => {
      ActivityVisibility.everyone: l10n.visibilityEveryone,
      ActivityVisibility.friendsOnly: l10n.visibilityFriendsOnly,
      ActivityVisibility.nobody: l10n.visibilityNobody,
    };

class PrivacyTab extends ConsumerStatefulWidget {
  const PrivacyTab({super.key});

  @override
  ConsumerState<PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends ConsumerState<PrivacyTab> {
  bool _saving = false;

  Future<void> _update({
    FriendRequestPrivacy? friendRequestPrivacy,
    DirectMessagePrivacy? directMessagePrivacy,
    ActivityVisibility? activityVisibility,
    bool? readReceiptsEnabled,
  }) async {
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(usersServiceProvider).updatePrivacy(
            friendRequestPrivacy: friendRequestPrivacy ?? profile.friendRequestPrivacy,
            directMessagePrivacy: directMessagePrivacy ?? profile.directMessagePrivacy,
            activityVisibility: activityVisibility ?? profile.activityVisibility,
            readReceiptsEnabled: readReceiptsEnabled ?? profile.readReceiptsEnabled,
          );
      ref.read(authControllerProvider.notifier).setProfile(updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorSavePrivacyFailed(e.message))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(authControllerProvider).profile;
    final friendRequestLabels = _friendRequestLabels(l10n);
    final directMessageLabels = _directMessageLabels(l10n);
    final activityLabels = _activityLabels(l10n);

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        Text(l10n.privacySafetyTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.md),
        if (profile == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          _PrivacyRow(
            label: l10n.whoCanSendFriendRequests,
            value: friendRequestLabels[profile.friendRequestPrivacy]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      friendRequestLabels,
                      profile.friendRequestPrivacy,
                      (value) => _update(friendRequestPrivacy: value),
                    ),
          ),
          _PrivacyRow(
            label: l10n.whoCanDirectMessage,
            value: directMessageLabels[profile.directMessagePrivacy]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      directMessageLabels,
                      profile.directMessagePrivacy,
                      (value) => _update(directMessagePrivacy: value),
                    ),
          ),
          _PrivacyRow(
            label: l10n.whoCanSeeActivity,
            value: activityLabels[profile.activityVisibility]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      activityLabels,
                      profile.activityVisibility,
                      (value) => _update(activityVisibility: value),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.readReceiptsLabel),
            subtitle: Text(l10n.readReceiptsSubtitle, style: TextStyle(color: colors.fgMuted)),
            value: profile.readReceiptsEnabled,
            onChanged: _saving ? null : (value) => _update(readReceiptsEnabled: value),
          ),
        ],
        const SizedBox(height: ConcordSpacing.xl),
        const Divider(),
        const SizedBox(height: ConcordSpacing.md),
        Text(l10n.blockedUsersTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.sm),
        const SizedBox(height: 400, child: BlockedTab()),
      ],
    );
  }

  Future<void> _pickOption<T>(
    BuildContext context,
    Map<T, String> labels,
    T current,
    ValueChanged<T> onSelected,
  ) async {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final selected = await showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in labels.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == current ? Icon(Icons.check, color: colors.brand) : null,
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onSelected(selected);
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: colors.fgMuted)),
          const SizedBox(width: ConcordSpacing.xs),
          Icon(Icons.chevron_right, color: colors.fgMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
