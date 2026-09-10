import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/presence_controller.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';

List<({PresenceStatus status, String label})> _statusOptions(AppLocalizations l10n) => [
      (status: PresenceStatus.online, label: l10n.statusOnline),
      (status: PresenceStatus.idle, label: l10n.statusIdle),
      (status: PresenceStatus.doNotDisturb, label: l10n.statusDoNotDisturb),
      (status: PresenceStatus.invisible, label: l10n.statusInvisible),
    ];

Future<void> showStatusPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(context: context, builder: (context) => const _StatusPickerSheet());
}

class _StatusPickerSheet extends ConsumerWidget {
  const _StatusPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(presenceControllerProvider.select((s) => s.myStatus));
    final statusOptions = _statusOptions(l10n);

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
            child: Text(l10n.setStatusTitle, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final option in statusOptions)
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
