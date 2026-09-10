import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../providers/presence_controller.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'status_picker_sheet.dart';

class UserPanelBar extends ConsumerWidget {
  const UserPanelBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final myStatus = ref.watch(presenceControllerProvider.select((s) => s.myStatus));

    final displayName = profile == null
        ? null
        : (profile.username?.isNotEmpty == true
              ? profile.username!
              : [profile.name, profile.surname].where((part) => part != null && part.isNotEmpty).join(' '));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.sm, vertical: ConcordSpacing.sm),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showStatusPickerSheet(context, ref),
            child: ConcordAvatar(
              imageUrl: profile?.avatarUrl,
              name: displayName,
              size: ConcordAvatarSize.sm,
              presence: concordPresenceFor(myStatus),
            ),
          ),
          const SizedBox(width: ConcordSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName?.isNotEmpty == true ? displayName! : l10n.loadingEllipsis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: colors.fgDefault),
                ),
                Text(
                  profile?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                ),
              ],
            ),
          ),
          ConcordIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.settingsTooltip,
            size: ConcordButtonSize.sm,
            onPressed: () => context.push('/settings'),
          ),
          ConcordIconButton(
            icon: Icons.logout,
            tooltip: l10n.logOutTooltip,
            size: ConcordButtonSize.sm,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
