import 'package:flutter/material.dart';

import 'concord_colors.dart';
import 'concord_tokens.dart';
import 'concord_typography.dart';

abstract final class ConcordTheme {
  static ThemeData dark({double fontScale = 1.0}) =>
      _build(ConcordColors.dark, Brightness.dark, fontScale);

  static ThemeData light({double fontScale = 1.0}) =>
      _build(ConcordColors.light, Brightness.light, fontScale);

  static ThemeData _build(ConcordColors colors, Brightness brightness, double fontScale) {
    final textTheme = _textTheme(colors, fontScale);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.fgOnBrand,
      secondary: colors.surfaceSidebar,
      onSecondary: colors.fgDefault,
      error: colors.dangerSolid,
      onError: colors.fgOnDanger,
      surface: colors.surfaceBase,
      onSurface: colors.fgDefault,
      outline: colors.borderDefault,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surfaceBase,
      canvasColor: colors.surfaceBase,
      dividerColor: colors.borderDefault,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: [colors, ConcordTypography(fontScale: fontScale)],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceBase,
        foregroundColor: colors.fgHeading,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors.borderSubtle,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: colors.fgDefault),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surfaceRail,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceSidebar,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          side: BorderSide(color: colors.borderDefault),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceFloating,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ConcordRadii.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceFloating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.fgDefault),
        actionTextColor: colors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ConcordRadii.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.brand),
      iconTheme: IconThemeData(color: colors.fgDefault),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.fgOnBrand,
          disabledBackgroundColor: colors.brand.withValues(alpha: 0.5),
          disabledForegroundColor: colors.fgOnBrand.withValues(alpha: 0.5),
          elevation: 0,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ConcordRadii.md)),
          textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.fgDefault,
          disabledForegroundColor: colors.fgDefault.withValues(alpha: 0.5),
          side: BorderSide(color: colors.borderDefault),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ConcordRadii.md)),
          textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(colors.fgDefault.withValues(alpha: 0.08)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.fgDefault,
          disabledForegroundColor: colors.fgDefault.withValues(alpha: 0.5),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ConcordRadii.md)),
          textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.brand,
        selectionColor: colors.brandBg,
        selectionHandleColor: colors.brand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceInput,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.fgDefault),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ConcordSpacing.md,
          vertical: ConcordSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          borderSide: BorderSide(color: colors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          borderSide: BorderSide(color: colors.danger, width: 2),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
      ),
    );
  }

  static ButtonStyle destructiveTextButtonStyle(ConcordColors colors) {
    return TextButton.styleFrom(
      foregroundColor: colors.danger,
      disabledForegroundColor: colors.danger.withValues(alpha: 0.5),
    );
  }

  static ButtonStyle destructiveButtonStyle(ConcordColors colors) {
    return ElevatedButton.styleFrom(
      backgroundColor: colors.dangerSolid,
      foregroundColor: colors.fgOnDanger,
      disabledBackgroundColor: colors.dangerSolid.withValues(alpha: 0.5),
      disabledForegroundColor: colors.fgOnDanger.withValues(alpha: 0.5),
    );
  }

  static TextTheme _textTheme(ConcordColors colors, double fontScale) {
    double size(double base) => base * fontScale;

    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: size(24),
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: colors.fgHeading,
      ),
      titleLarge: TextStyle(
        fontSize: size(20),
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: colors.fgHeading,
      ),
      titleMedium: TextStyle(
        fontSize: size(17),
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: colors.fgHeading,
      ),
      bodyLarge: TextStyle(fontSize: size(15), height: 22 / 15, color: colors.fgDefault),
      bodyMedium: TextStyle(fontSize: size(13), height: 18 / 13, color: colors.fgDefault),
      bodySmall: TextStyle(fontSize: size(12), height: 16 / 12, color: colors.fgMuted),
      labelLarge: TextStyle(
        fontSize: size(13),
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: colors.fgDefault,
      ),
      labelSmall: TextStyle(fontSize: size(11), height: 14 / 11, color: colors.fgMuted),
    );
  }
}
