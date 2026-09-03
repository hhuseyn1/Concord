import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum ConcordButtonVariant { primary, secondary, ghost, danger, link }

enum ConcordButtonSize { sm, md, lg }

class ConcordButton extends StatelessWidget {
  const ConcordButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ConcordButtonVariant.primary,
    this.size = ConcordButtonSize.md,
    this.leading,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ConcordButtonVariant variant;
  final ConcordButtonSize size;
  final Widget? leading;
  final bool loading;

  final bool expand;

  double get _height => switch (size) {
    ConcordButtonSize.sm => 32,
    ConcordButtonSize.md => 36,
    ConcordButtonSize.lg => 44,
  };

  EdgeInsets get _padding => switch (size) {
    ConcordButtonSize.sm => const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
    ConcordButtonSize.md => const EdgeInsets.symmetric(horizontal: ConcordSpacing.lg),
    ConcordButtonSize.lg => const EdgeInsets.symmetric(horizontal: ConcordSpacing.xl - 4),
  };

  TextStyle? _textStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return switch (size) {
      ConcordButtonSize.sm => textTheme.bodySmall,
      ConcordButtonSize.md => textTheme.bodyMedium,
      ConcordButtonSize.lg => textTheme.bodyLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final disabled = onPressed == null || loading;

    if (variant == ConcordButtonVariant.link) {
      return _LinkButton(
        label: label,
        onPressed: disabled ? null : onPressed,
        colors: colors,
        textStyle: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final (Color background, Color foreground, Color? pressedOverlay) = switch (variant) {
      ConcordButtonVariant.primary => (colors.brand, colors.fgOnBrand, colors.brandPressed),
      ConcordButtonVariant.secondary => (
        colors.fgDefault.withValues(alpha: 0.1),
        colors.fgDefault,
        colors.fgDefault.withValues(alpha: 0.2),
      ),
      ConcordButtonVariant.ghost => (
        Colors.transparent,
        colors.fgDefault,
        colors.fgDefault.withValues(alpha: 0.15),
      ),
      ConcordButtonVariant.danger => (
        colors.dangerSolid,
        colors.fgOnDanger,
        colors.dangerSolidPressed,
      ),
      ConcordButtonVariant.link => (Colors.transparent, colors.brand, null),
    };

    Widget child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
          const SizedBox(width: ConcordSpacing.sm),
        ] else if (leading != null) ...[
          IconTheme(
            data: IconThemeData(color: foreground, size: 16),
            child: leading!,
          ),
          const SizedBox(width: ConcordSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: _textStyle(context)?.copyWith(color: foreground, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: _height,
      child: Material(
        color: disabled ? background.withValues(alpha: 0.5) : background,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          overlayColor: pressedOverlay == null
              ? null
              : WidgetStateProperty.all(pressedOverlay.withValues(alpha: 0.24)),
          child: Padding(padding: _padding, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.onPressed,
    required this.colors,
    required this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final ConcordColors colors;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(ConcordRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: textStyle?.copyWith(
            color: onPressed == null ? colors.brand.withValues(alpha: 0.5) : colors.brand,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: colors.brand,
          ),
        ),
      ),
    );
  }
}
