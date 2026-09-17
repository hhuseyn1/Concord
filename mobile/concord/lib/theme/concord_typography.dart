import 'package:flutter/material.dart';

/// Carries the user's text-size multiplier (Settings > Appearance > Text size)
/// through the theme, for the handful of places that need a font size the
/// [TextTheme] ramp doesn't cover.
///
/// Anything styled from `Theme.of(context).textTheme` already scales - the ramp
/// itself is built with the multiplier applied (see `ConcordTheme._textTheme`).
/// This exists for widgets that legitimately need an off-ramp size (chat
/// message body copy at 14, a 10pt inline timestamp, ...): they multiply their
/// own base size through [size] instead of hardcoding a number that would
/// quietly ignore the preference.
///
/// Spacing, padding, icon sizes and button heights deliberately do *not* use
/// this - only type scales, so layouts stay intact at every step.
@immutable
class ConcordTypography extends ThemeExtension<ConcordTypography> {
  const ConcordTypography({required this.fontScale});

  final double fontScale;

  /// [base] at the default text size, scaled to the user's chosen step.
  double size(double base) => base * fontScale;

  static ConcordTypography of(BuildContext context) {
    return Theme.of(context).extension<ConcordTypography>() ?? const ConcordTypography(fontScale: 1);
  }

  @override
  ConcordTypography copyWith({double? fontScale}) {
    return ConcordTypography(fontScale: fontScale ?? this.fontScale);
  }

  @override
  ConcordTypography lerp(ThemeExtension<ConcordTypography>? other, double t) {
    if (other is! ConcordTypography) return this;
    return ConcordTypography(fontScale: fontScale + (other.fontScale - fontScale) * t);
  }
}
