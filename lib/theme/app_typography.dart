import 'package:flutter/material.dart';

/// Geist Sans typography for the app.
abstract final class AppFonts {
  static const String family = 'GeistSans';

  static TextStyle geist({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  /// Large headings (replaces former Playfair Display usage).
  static TextStyle display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return geist(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme([TextTheme? base]) {
    final theme = (base ?? ThemeData.light().textTheme).apply(
      fontFamily: family,
    );

    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: theme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: theme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: theme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: theme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: theme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: theme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: theme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: theme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      labelMedium: theme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: theme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
