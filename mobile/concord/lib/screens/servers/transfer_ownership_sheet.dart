import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Future<void> showTransferOwnershipSheet(
  BuildContext context,
  WidgetRef ref, {
  required String serverId,
  required String serverName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TransferOwnershipSheet(serverId: serverId, serverName: serverName),
  );
}

class _TransferOwnershipSheet extends ConsumerStatefulWidget {
  const _TransferOwnershipSheet({required this.serverId, required this.serverName});

  final String serverId;
  final String serverName;

  @override
  ConsumerState<_TransferOwnershipSheet> createState() => _TransferOwnershipSheetState();
}

class _TransferOwnershipSheetState extends ConsumerState<_TransferOwnershipSheet> {
  final _queryController = TextEditingController();
  String? _selectedUserId;
  String? _selectedDisplayName;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndTransfer() async {
    final userId = _selectedUserId;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer ownership of ${widget.serverName}?'),
        content: Text(
          "$_selectedDisplayName will become the new owner. You'll remain a member and will then be able to "
          'leave the server yourself if you want to.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Transfer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(serversServiceProvider).transferOwnership(serverId: widget.serverId, newOwnerUserId: userId);
      ref.invalidate(myPermissionsProvider(widget.serverId));
      ref.invalidate(myServersProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message.isNotEmpty ? e.message : 'Could not transfer ownership.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final currentUserId = ref.watch(authControllerProvider).profile?.id;
    final membersAsync = ref.watch(serverMembersProvider(widget.serverId));
    final query = _queryController.text.trim().toLowerCase();

    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer ownership', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pick another member to become the new owner of ${widget.serverName}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.fgMuted),
            ),
            const SizedBox(height: ConcordSpacing.md),
            ConcordTextField(
              controller: _queryController,
              hint: 'Filter members by username…',
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: ConcordSpacing.sm),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: ConcordSpacing.md),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    "Couldn't load members.",
                    style: TextStyle(color: colors.fgMuted),
                  ),
                ),
                data: (members) {
                  final candidates = members.where((m) => m.user.id != currentUserId).where((m) {
                    if (query.isEmpty) return true;
                    return displayNameFor(m.user).toLowerCase().contains(query);
                  }).toList();

                  if (candidates.isEmpty) {
                    return Center(
                      child: Text(
                        "There's nobody else in this server to transfer ownership to yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.fgMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final member = candidates[index];
                      final name = displayNameFor(member.user);
                      final selected = _selectedUserId == member.user.id;
                      return ListTile(
                        leading: ConcordAvatar(imageUrl: member.user.avatarUrl, name: name, size: ConcordAvatarSize.sm),
                        title: Text(name),
                        selected: selected,
                        selectedTileColor: colors.brandBg,
                        trailing: selected ? Icon(Icons.check_circle, color: colors.brand) : null,
                        onTap: _submitting
                            ? null
                            : () => setState(() {
                                  _selectedUserId = member.user.id;
                                  _selectedDisplayName = name;
                                }),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: ConcordSpacing.md),
            Row(
              children: [
                const Spacer(),
                ConcordButton(
                  label: 'Cancel',
                  variant: ConcordButtonVariant.secondary,
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: ConcordSpacing.sm),
                ConcordButton(
                  label: 'Transfer',
                  variant: ConcordButtonVariant.danger,
                  loading: _submitting,
                  onPressed: (_selectedUserId == null || _submitting) ? null : _confirmAndTransfer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
