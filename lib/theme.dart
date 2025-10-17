// lib/theme.dart
import 'package:flutter/material.dart';

final inputBorderRadius = BorderRadius.circular(14);
final buttonBorderRadius = BorderRadius.circular(30);

ThemeData buildTheme(ColorScheme colorScheme) {
  final theme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,

    bottomAppBarTheme: BottomAppBarThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 2,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      //enabledBorder: OutlineInputBorder(
      //  borderRadius: inputBorderRadius,
      //  borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
      //),
      //focusedBorder: OutlineInputBorder(
      //  borderRadius: inputBorderRadius,
      //  borderSide: BorderSide(color: colorScheme.primary, width: 2),
      //),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      errorStyle: TextStyle(color: colorScheme.error),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary, 
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 4,
      titleTextStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.tertiary,
      foregroundColor: colorScheme.onTertiary
    )
  );
  return theme;
}
