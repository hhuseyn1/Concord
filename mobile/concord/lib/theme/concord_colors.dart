import 'package:flutter/material.dart';

@immutable
class ConcordColors extends ThemeExtension<ConcordColors> {
  const ConcordColors({
    required this.surfaceRail,
    required this.surfaceSidebar,
    required this.surfaceBase,
    required this.surfaceFloating,
    required this.borderDefault,
    required this.borderSubtle,
    required this.fgDefault,
    required this.fgMuted,
    required this.fgLink,
    required this.fgHeading,
    required this.fgOnBrand,
    required this.fgOnDanger,
    required this.brand,
    required this.brandHover,
    required this.brandPressed,
    required this.brandBg,
    required this.danger,
    required this.dangerBg,
    required this.dangerSolid,
    required this.dangerSolidHover,
    required this.dangerSolidPressed,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.info,
    required this.infoBg,
    required this.presenceOnline,
    required this.presenceIdle,
    required this.presenceDnd,
    required this.presenceOffline,
  });

  final Color surfaceRail;
  final Color surfaceSidebar;
  final Color surfaceBase;
  final Color surfaceFloating;

  final Color borderDefault;
  final Color borderSubtle;

  final Color fgDefault;
  final Color fgMuted;
  final Color fgLink;
  final Color fgHeading;
  final Color fgOnBrand;
  final Color fgOnDanger;

  final Color brand;
  final Color brandHover;
  final Color brandPressed;
  final Color brandBg;

  final Color danger;
  final Color dangerBg;
  final Color dangerSolid;
  final Color dangerSolidHover;
  final Color dangerSolidPressed;

  final Color success;
  final Color successBg;

  final Color warning;
  final Color warningBg;

  final Color info;
  final Color infoBg;

  final Color presenceOnline;
  final Color presenceIdle;
  final Color presenceDnd;
  final Color presenceOffline;

  static const dark = ConcordColors(
    surfaceRail: Color(0xFF17131F),
    surfaceSidebar: Color(0xFF1E1929),
    surfaceBase: Color(0xFF262032),
    surfaceFloating: Color(0xFF120E19),
    borderDefault: Color(0xFF33303E),
    borderSubtle: Color(0xFF262330),
    fgDefault: Color(0xFFDCDBE3),
    fgMuted: Color(0xFF948F9E),
    fgLink: Color(0xFFC084FC),
    fgHeading: Color(0xFFF5F3F9),
    fgOnBrand: Color(0xFF1A1625),
    fgOnDanger: Color(0xFFFFFFFF),
    brand: Color(0xFFC084FC),
    brandHover: Color(0xFFD1A3FD),
    brandPressed: Color(0xFFA855F7),
    brandBg: Color(0x26C084FC),
    danger: Color(0xFFF87171),
    dangerBg: Color(0x26F87171),
    dangerSolid: Color(0xFFDC2626),
    dangerSolidHover: Color(0xFFB91C1C),
    dangerSolidPressed: Color(0xFF991B1B),
    success: Color(0xFF4ADE80),
    successBg: Color(0x264ADE80),
    warning: Color(0xFFFBBF24),
    warningBg: Color(0x26FBBF24),
    info: Color(0xFF60A5FA),
    infoBg: Color(0x2660A5FA),
    presenceOnline: Color(0xFF3BA55D),
    presenceIdle: Color(0xFFF0B232),
    presenceDnd: Color(0xFFED4245),
    presenceOffline: Color(0xFF80848E),
  );

  static const light = ConcordColors(
    surfaceRail: Color(0xFFE3DDEC),
    surfaceSidebar: Color(0xFFEEE9F5),
    surfaceBase: Color(0xFFFFFFFF),
    surfaceFloating: Color(0xFFFBFAFF),
    borderDefault: Color(0xFFE5E4E7),
    borderSubtle: Color(0xFFEFEEF2),
    fgDefault: Color(0xFF4A4453),
    fgMuted: Color(0xFF6B6375),
    fgLink: Color(0xFFAA3BFF),
    fgHeading: Color(0xFF08060D),
    fgOnBrand: Color(0xFFFFFFFF),
    fgOnDanger: Color(0xFFFFFFFF),
    brand: Color(0xFFAA3BFF),
    brandHover: Color(0xFF9526E8),
    brandPressed: Color(0xFF7F1FC7),
    brandBg: Color(0x1AAA3BFF),
    dangerSolid: Color(0xFFDC2626),
    dangerSolidHover: Color(0xFFB91C1C),
    dangerSolidPressed: Color(0xFF991B1B),
    danger: Color(0xFFDC2626),
    dangerBg: Color(0x1ADC2626),
    success: Color(0xFF16A34A),
    successBg: Color(0x1A16A34A),
    warning: Color(0xFFB45309),
    warningBg: Color(0x1AB45309),
    info: Color(0xFF2563EB),
    infoBg: Color(0x1A2563EB),
    presenceOnline: Color(0xFF3BA55D),
    presenceIdle: Color(0xFFF0B232),
    presenceDnd: Color(0xFFED4245),
    presenceOffline: Color(0xFF80848E),
  );

  @override
  ConcordColors copyWith({
    Color? surfaceRail,
    Color? surfaceSidebar,
    Color? surfaceBase,
    Color? surfaceFloating,
    Color? borderDefault,
    Color? borderSubtle,
    Color? fgDefault,
    Color? fgMuted,
    Color? fgLink,
    Color? fgHeading,
    Color? fgOnBrand,
    Color? fgOnDanger,
    Color? brand,
    Color? brandHover,
    Color? brandPressed,
    Color? brandBg,
    Color? danger,
    Color? dangerBg,
    Color? dangerSolid,
    Color? dangerSolidHover,
    Color? dangerSolidPressed,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? info,
    Color? infoBg,
    Color? presenceOnline,
    Color? presenceIdle,
    Color? presenceDnd,
    Color? presenceOffline,
  }) {
    return ConcordColors(
      surfaceRail: surfaceRail ?? this.surfaceRail,
      surfaceSidebar: surfaceSidebar ?? this.surfaceSidebar,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceFloating: surfaceFloating ?? this.surfaceFloating,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      fgDefault: fgDefault ?? this.fgDefault,
      fgMuted: fgMuted ?? this.fgMuted,
      fgLink: fgLink ?? this.fgLink,
      fgHeading: fgHeading ?? this.fgHeading,
      fgOnBrand: fgOnBrand ?? this.fgOnBrand,
      fgOnDanger: fgOnDanger ?? this.fgOnDanger,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandPressed: brandPressed ?? this.brandPressed,
      brandBg: brandBg ?? this.brandBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerSolid: dangerSolid ?? this.dangerSolid,
      dangerSolidHover: dangerSolidHover ?? this.dangerSolidHover,
      dangerSolidPressed: dangerSolidPressed ?? this.dangerSolidPressed,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      presenceOnline: presenceOnline ?? this.presenceOnline,
      presenceIdle: presenceIdle ?? this.presenceIdle,
      presenceDnd: presenceDnd ?? this.presenceDnd,
      presenceOffline: presenceOffline ?? this.presenceOffline,
    );
  }

  @override
  ConcordColors lerp(ThemeExtension<ConcordColors>? other, double t) {
    if (other is! ConcordColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return ConcordColors(
      surfaceRail: c(surfaceRail, other.surfaceRail),
      surfaceSidebar: c(surfaceSidebar, other.surfaceSidebar),
      surfaceBase: c(surfaceBase, other.surfaceBase),
      surfaceFloating: c(surfaceFloating, other.surfaceFloating),
      borderDefault: c(borderDefault, other.borderDefault),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      fgDefault: c(fgDefault, other.fgDefault),
      fgMuted: c(fgMuted, other.fgMuted),
      fgLink: c(fgLink, other.fgLink),
      fgHeading: c(fgHeading, other.fgHeading),
      fgOnBrand: c(fgOnBrand, other.fgOnBrand),
      fgOnDanger: c(fgOnDanger, other.fgOnDanger),
      brand: c(brand, other.brand),
      brandHover: c(brandHover, other.brandHover),
      brandPressed: c(brandPressed, other.brandPressed),
      brandBg: c(brandBg, other.brandBg),
      danger: c(danger, other.danger),
      dangerBg: c(dangerBg, other.dangerBg),
      dangerSolid: c(dangerSolid, other.dangerSolid),
      dangerSolidHover: c(dangerSolidHover, other.dangerSolidHover),
      dangerSolidPressed: c(dangerSolidPressed, other.dangerSolidPressed),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      warning: c(warning, other.warning),
      warningBg: c(warningBg, other.warningBg),
      info: c(info, other.info),
      infoBg: c(infoBg, other.infoBg),
      presenceOnline: c(presenceOnline, other.presenceOnline),
      presenceIdle: c(presenceIdle, other.presenceIdle),
      presenceDnd: c(presenceDnd, other.presenceDnd),
      presenceOffline: c(presenceOffline, other.presenceOffline),
    );
  }
}

enum ConcordPresence { online, idle, dnd, offline }

extension ConcordPresenceColor on ConcordColors {
  Color presenceColor(ConcordPresence presence) {
    switch (presence) {
      case ConcordPresence.online:
        return presenceOnline;
      case ConcordPresence.idle:
        return presenceIdle;
      case ConcordPresence.dnd:
        return presenceDnd;
      case ConcordPresence.offline:
        return presenceOffline;
    }
  }
}
