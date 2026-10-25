// Material 3 themes built from the palette. Only long-stable theme classes are used on purpose
// (NavigationBarThemeData, SnackBarThemeData, BottomSheetThemeData, DividerThemeData), so the file keeps
// compiling across Flutter releases.

import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final Palette p = isDark ? Palette.dark : Palette.light;

  final ColorScheme scheme = isDark
      ? ColorScheme.dark(
          primary: p.primary,
          onPrimary: Colors.white,
          primaryContainer: p.primary.withValues(alpha: 0.22),
          onPrimaryContainer: p.text,
          secondary: p.brand,
          onSecondary: Colors.white,
          secondaryContainer: p.primary.withValues(alpha: 0.22),
          onSecondaryContainer: p.text,
          error: p.err,
          onError: Colors.white,
          surface: p.panel,
          onSurface: p.text,
          outline: p.line,
          outlineVariant: p.line,
        )
      : ColorScheme.light(
          primary: p.primary,
          onPrimary: Colors.white,
          primaryContainer: p.primary.withValues(alpha: 0.14),
          onPrimaryContainer: p.text,
          secondary: p.brand,
          onSecondary: Colors.white,
          secondaryContainer: p.primary.withValues(alpha: 0.14),
          onSecondaryContainer: p.text,
          error: p.err,
          onError: Colors.white,
          surface: p.panel,
          onSurface: p.text,
          outline: p.line,
          outlineVariant: p.line,
        );

  // Material 3 is the default since Flutter 3.16, so it is not requested explicitly.
  final ThemeData base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: appFont,
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.panelAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: appFont, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: p.line),
        textStyle: const TextStyle(fontFamily: appFont, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.primary.withValues(alpha: isDark ? 0.24 : 0.14),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
        final bool selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: appFont,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? p.primary : p.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((Set<WidgetState> states) {
        final bool selected = states.contains(WidgetState.selected);
        return IconThemeData(size: 24, color: selected ? p.primary : p.muted);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF1B2230) : const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(fontFamily: appFont, fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
  );
}
