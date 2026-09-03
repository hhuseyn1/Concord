import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_providers.dart';
import '../../theme/theme.dart';

class TypingIndicatorBar extends ConsumerWidget {
  const TypingIndicatorBar({super.key, required this.typingUserIds});

  final Set<String> typingUserIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = typingUserIds.toList();
    if (ids.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<ConcordColors>()!;
    final firstName = ids.isNotEmpty ? _watchName(ref, ids[0]) : null;
    final secondName = ids.length > 1 ? _watchName(ref, ids[1]) : null;

    final text = switch (ids.length) {
      1 => '$firstName is typing…',
      2 => '$firstName and $secondName are typing…',
      _ => '$firstName, $secondName, and others are typing…',
    };

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.lg),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Center(
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.fgMuted),
              ),
            ),
          ),
          const SizedBox(width: ConcordSpacing.sm),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.fgMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _watchName(WidgetRef ref, String userId) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    return profileAsync.maybeWhen(data: (profile) => displayNameFor(profile, fallback: 'Someone'), orElse: () => 'Someone');
  }
}
