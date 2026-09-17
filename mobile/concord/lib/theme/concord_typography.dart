import 'package:flutter/material.dart';

@immutable
class ConcordTypography extends ThemeExtension<ConcordTypography> {
  const ConcordTypography({required this.fontScale});

  final double fontScale;

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
