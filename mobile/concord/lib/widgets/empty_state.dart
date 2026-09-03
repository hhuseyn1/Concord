import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ConcordEmptyState extends StatelessWidget {
  const ConcordEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? ConcordSpacing.md : ConcordSpacing.xxl,
        horizontal: ConcordSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 28 : 40, color: colors.fgMuted),
          SizedBox(height: compact ? ConcordSpacing.sm : ConcordSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (compact ? textTheme.bodyMedium : textTheme.bodyLarge)?.copyWith(
              color: colors.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
            ),
          ],
          if (action != null) ...[SizedBox(height: compact ? ConcordSpacing.sm : ConcordSpacing.md), action!],
        ],
      ),
    );
  }
}
