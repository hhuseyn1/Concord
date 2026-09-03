import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class FriendRow extends StatelessWidget {
  const FriendRow({
    super.key,
    required this.user,
    this.actions,
    this.subtitle,
    this.showPresence = true,
    this.onTap,
  });

  final PublicProfileResponse user;
  final Widget? actions;
  final String? subtitle;
  final bool showPresence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final displayName = displayNameFor(user);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ConcordRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
        child: Row(
          children: [
            ConcordAvatar(
              imageUrl: user.avatarUrl,
              name: displayName,
              size: ConcordAvatarSize.md,
              presence: showPresence ? concordPresenceFor(user.status) : null,
            ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: colors.fgDefault),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                    ),
                ],
              ),
            ),
            if (actions != null) ...[
              const SizedBox(width: ConcordSpacing.sm),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}
