import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../friends/blocked_tab.dart';

const _friendRequestLabels = {
  FriendRequestPrivacy.everyone: 'Everyone',
  FriendRequestPrivacy.friendsOfFriends: 'Friends of friends',
  FriendRequestPrivacy.nobody: 'Nobody',
};

const _directMessageLabels = {
  DirectMessagePrivacy.everyone: 'Everyone',
  DirectMessagePrivacy.friendsOnly: 'Friends only',
  DirectMessagePrivacy.nobody: 'Nobody',
};

const _activityLabels = {
  ActivityVisibility.everyone: 'Everyone',
  ActivityVisibility.friendsOnly: 'Friends only',
  ActivityVisibility.nobody: 'Nobody',
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
            .showSnackBar(SnackBar(content: Text('Could not save privacy settings: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(authControllerProvider).profile;

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        Text('Privacy & Safety', style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.md),
        if (profile == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          _PrivacyRow(
            label: 'Who can send friend requests',
            value: _friendRequestLabels[profile.friendRequestPrivacy]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      _friendRequestLabels,
                      profile.friendRequestPrivacy,
                      (value) => _update(friendRequestPrivacy: value),
                    ),
          ),
          _PrivacyRow(
            label: 'Who can direct message you',
            value: _directMessageLabels[profile.directMessagePrivacy]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      _directMessageLabels,
                      profile.directMessagePrivacy,
                      (value) => _update(directMessagePrivacy: value),
                    ),
          ),
          _PrivacyRow(
            label: 'Who can see your activity',
            value: _activityLabels[profile.activityVisibility]!,
            onTap: _saving
                ? null
                : () => _pickOption(
                      context,
                      _activityLabels,
                      profile.activityVisibility,
                      (value) => _update(activityVisibility: value),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Read receipts'),
            subtitle: Text('Let others see when you\'ve read their messages.', style: TextStyle(color: colors.fgMuted)),
            value: profile.readReceiptsEnabled,
            onChanged: _saving ? null : (value) => _update(readReceiptsEnabled: value),
          ),
        ],
        const SizedBox(height: ConcordSpacing.xl),
        const Divider(),
        const SizedBox(height: ConcordSpacing.md),
        Text('Blocked Users', style: textTheme.titleMedium),
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
