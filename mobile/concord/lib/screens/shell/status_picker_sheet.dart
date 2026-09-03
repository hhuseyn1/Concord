import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/presence_controller.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';

const _statusOptions = [
  (status: PresenceStatus.online, label: 'Online'),
  (status: PresenceStatus.idle, label: 'Idle'),
  (status: PresenceStatus.doNotDisturb, label: 'Do Not Disturb'),
  (status: PresenceStatus.invisible, label: 'Invisible'),
];

Future<void> showStatusPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(context: context, builder: (context) => const _StatusPickerSheet());
}

class _StatusPickerSheet extends ConsumerWidget {
  const _StatusPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final current = ref.watch(presenceControllerProvider.select((s) => s.myStatus));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ConcordSpacing.lg,
              ConcordSpacing.lg,
              ConcordSpacing.lg,
              ConcordSpacing.sm,
            ),
            child: Text('Set status', style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final option in _statusOptions)
            ListTile(
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.presenceColor(concordPresenceFor(option.status)),
                ),
              ),
              title: Text(option.label, style: TextStyle(color: colors.fgDefault)),
              trailing: option.status == current ? Icon(Icons.check, color: colors.brand) : null,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(presenceControllerProvider.notifier).setStatus(option.status);
              },
            ),
          const SizedBox(height: ConcordSpacing.sm),
        ],
      ),
    );
  }
}
