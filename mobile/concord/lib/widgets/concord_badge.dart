import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum ConcordBadgeVariant { neutral, brand, danger, success, warning, info }

class ConcordBadge extends StatelessWidget {
  const ConcordBadge({super.key, required this.label, this.variant = ConcordBadgeVariant.neutral});

  final String label;
  final ConcordBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    // Badge copy is real text, so it follows the user's text-size preference
    // like everything else - the pill's height is text + fixed padding, so it
    // grows with it without disturbing anything around it.
    final type = ConcordTypography.of(context);
    final (Color background, Color foreground) = switch (variant) {
      ConcordBadgeVariant.neutral => (colors.fgDefault.withValues(alpha: 0.1), colors.fgDefault),
      ConcordBadgeVariant.brand => (colors.brandBg, colors.brand),
      ConcordBadgeVariant.danger => (colors.dangerBg, colors.danger),
      ConcordBadgeVariant.success => (colors.successBg, colors.success),
      ConcordBadgeVariant.warning => (colors.warningBg, colors.warning),
      ConcordBadgeVariant.info => (colors.infoBg, colors.info),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ConcordRadii.full)),
      child: Text(
        label,
        style: TextStyle(fontSize: type.size(12), fontWeight: FontWeight.w500, color: foreground, height: 1),
      ),
    );
  }
}
