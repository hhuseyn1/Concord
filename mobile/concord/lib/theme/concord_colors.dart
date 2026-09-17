import 'package:flutter/material.dart';

@immutable
class ConcordColors extends ThemeExtension<ConcordColors> {
  const ConcordColors({
    required this.surfaceRail,
    required this.surfaceSidebar,
    required this.surfaceBase,
    required this.surfaceFloating,
    required this.surfaceInput,
    required this.borderDefault,
    required this.borderSubtle,
    required this.fgDefault,
    required this.fgMuted,
    required this.fgFaint,
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

  final Color surfaceInput;

  final Color borderDefault;
  final Color borderSubtle;

  final Color fgDefault;
  final Color fgMuted;
  final Color fgFaint;
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
    surfaceRail: Color(0xFF1E1F22),
    surfaceSidebar: Color(0xFF2B2D31),
    surfaceBase: Color(0xFF313338),
    surfaceFloating: Color(0xFF1E1F22),
    surfaceInput: Color(0xFF1E1F22),
    borderDefault: Color(0xFF3F4147),
    borderSubtle: Color(0xFF35373C),
    fgDefault: Color(0xFFF2F3F5),
    fgMuted: Color(0xFFB5BAC1),
    fgFaint: Color(0xFF949BA4),
    fgLink: Color(0xFF949CF7),
    fgHeading: Color(0xFFFFFFFF),
    fgOnBrand: Color(0xFFFFFFFF),
    fgOnDanger: Color(0xFFFFFFFF),
    brand: Color(0xFF5865F2),
    brandHover: Color(0xFF4752C4),
    brandPressed: Color(0xFF3C45A5),
    brandBg: Color(0x2E5865F2),
    danger: Color(0xFFF23F42),
    dangerBg: Color(0x26F23F42),
    dangerSolid: Color(0xFFDA373C),
    dangerSolidHover: Color(0xFFA12828),
    dangerSolidPressed: Color(0xFF8B1D1D),
    success: Color(0xFF23A559),
    successBg: Color(0x2623A559),
    warning: Color(0xFFF0B232),
    warningBg: Color(0x26F0B232),
    info: Color(0xFF60A5FA),
    infoBg: Color(0x2660A5FA),
    presenceOnline: Color(0xFF23A559),
    presenceIdle: Color(0xFFF0B232),
    presenceDnd: Color(0xFFF23F42),
    presenceOffline: Color(0xFF80848E),
  );

  static const light = ConcordColors(
    surfaceRail: Color(0xFFE3E5E8),
    surfaceSidebar: Color(0xFFE3E5E8),
    surfaceBase: Color(0xFFF2F3F5),
    surfaceFloating: Color(0xFFFFFFFF),
    surfaceInput: Color(0xFFEBEDEF),
    borderDefault: Color(0xFFD4D7DC),
    borderSubtle: Color(0xFFE3E5E8),
    fgDefault: Color(0xFF1E1F22),
    fgMuted: Color(0xFF4E5058),
    fgFaint: Color(0xFF747F8D),
    fgLink: Color(0xFF4752C4),
    fgHeading: Color(0xFF060607),
    fgOnBrand: Color(0xFFFFFFFF),
    fgOnDanger: Color(0xFFFFFFFF),
    brand: Color(0xFF5865F2),
    brandHover: Color(0xFF4752C4),
    brandPressed: Color(0xFF3C45A5),
    brandBg: Color(0x1A5865F2),
    danger: Color(0xFFD83C3E),
    dangerBg: Color(0x1AD83C3E),
    dangerSolid: Color(0xFFDA373C),
    dangerSolidHover: Color(0xFFA12828),
    dangerSolidPressed: Color(0xFF8B1D1D),
    success: Color(0xFF248046),
    successBg: Color(0x1A248046),
    warning: Color(0xFFC47F00),
    warningBg: Color(0x1AC47F00),
    info: Color(0xFF2563EB),
    infoBg: Color(0x1A2563EB),
    presenceOnline: Color(0xFF23A559),
    presenceIdle: Color(0xFFF0B232),
    presenceDnd: Color(0xFFF23F42),
    presenceOffline: Color(0xFF80848E),
  );

  @override
  ConcordColors copyWith({
    Color? surfaceRail,
    Color? surfaceSidebar,
    Color? surfaceBase,
    Color? surfaceFloating,
    Color? surfaceInput,
    Color? borderDefault,
    Color? borderSubtle,
    Color? fgDefault,
    Color? fgMuted,
    Color? fgFaint,
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
      surfaceInput: surfaceInput ?? this.surfaceInput,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      fgDefault: fgDefault ?? this.fgDefault,
      fgMuted: fgMuted ?? this.fgMuted,
      fgFaint: fgFaint ?? this.fgFaint,
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
      surfaceInput: c(surfaceInput, other.surfaceInput),
      borderDefault: c(borderDefault, other.borderDefault),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      fgDefault: c(fgDefault, other.fgDefault),
      fgMuted: c(fgMuted, other.fgMuted),
      fgFaint: c(fgFaint, other.fgFaint),
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
