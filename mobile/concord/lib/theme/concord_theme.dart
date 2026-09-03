import 'package:flutter/material.dart';

import 'concord_colors.dart';
import 'concord_tokens.dart';

abstract final class ConcordTheme {
  static ThemeData dark() => _build(ConcordColors.dark, Brightness.dark);

  static ThemeData light() => _build(ConcordColors.light, Brightness.light);

  static ThemeData _build(ConcordColors colors, Brightness brightness) {
    final textTheme = _textTheme(colors);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.fgOnBrand,
      secondary: colors.brand,
      onSecondary: colors.fgOnBrand,
      error: colors.dangerSolid,
      onError: colors.fgOnDanger,
      surface: colors.surfaceBase,
      onSurface: colors.fgDefault,
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
      extensions: [colors],
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
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.brand,
        selectionColor: colors.brandBg,
        selectionHandleColor: colors.brand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSidebar,
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

  static TextTheme _textTheme(ConcordColors colors) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: colors.fgHeading,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: colors.fgHeading,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: colors.fgHeading,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 22 / 15, color: colors.fgDefault),
      bodyMedium: TextStyle(fontSize: 13, height: 18 / 13, color: colors.fgDefault),
      bodySmall: TextStyle(fontSize: 12, height: 16 / 12, color: colors.fgMuted),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: colors.fgDefault,
      ),
      labelSmall: TextStyle(fontSize: 11, height: 14 / 11, color: colors.fgMuted),
    );
  }
}
