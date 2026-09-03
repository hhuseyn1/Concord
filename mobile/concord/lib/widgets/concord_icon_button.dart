import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'concord_button.dart';

class ConcordIconButton extends StatelessWidget {
  const ConcordIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.variant = ConcordButtonVariant.ghost,
    this.size = ConcordButtonSize.md,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ConcordButtonVariant variant;
  final ConcordButtonSize size;

  final bool selected;

  double get _dimension => switch (size) {
    ConcordButtonSize.sm => 32,
    ConcordButtonSize.md => 36,
    ConcordButtonSize.lg => 44,
  };

  double get _iconSize => switch (size) {
    ConcordButtonSize.sm => 16,
    ConcordButtonSize.md => 18,
    ConcordButtonSize.lg => 20,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final effectiveVariant = selected && variant == ConcordButtonVariant.ghost
        ? ConcordButtonVariant.secondary
        : variant;
    final disabled = onPressed == null;

    final (Color background, Color foreground) = switch (effectiveVariant) {
      ConcordButtonVariant.primary => (colors.brand, colors.fgOnBrand),
      ConcordButtonVariant.secondary => (colors.fgDefault.withValues(alpha: 0.1), colors.fgDefault),
      ConcordButtonVariant.ghost => (Colors.transparent, colors.fgMuted),
      ConcordButtonVariant.danger => (colors.dangerSolid, colors.fgOnDanger),
      ConcordButtonVariant.link => (Colors.transparent, colors.brand),
    };

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: SizedBox(
          width: _dimension,
          height: _dimension,
          child: Material(
            color: disabled ? background.withValues(alpha: 0.5) : background,
            borderRadius: BorderRadius.circular(ConcordRadii.md),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              child: Icon(icon, size: _iconSize, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
