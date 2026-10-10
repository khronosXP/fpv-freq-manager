import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// UI Max Pro — Ultra-clean, high-contrast, daylight tactical theme
  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0265DC), // Tactical Cobalt Blue
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF0265DC),
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFFE0F2FE),
          onPrimaryContainer: const Color(0xFF0369A1),
          secondary: const Color(0xFFB45309), // Amber 700 / Deep Ochre
          onSecondary: const Color(0xFFFFFFFF),
          secondaryContainer: const Color(0xFFFEF3C7),
          onSecondaryContainer: const Color(0xFF92400E),
          tertiary: const Color(0xFF047857), // Emerald 700
          onTertiary: const Color(0xFFFFFFFF),
          tertiaryContainer: const Color(0xFFD1FAE5),
          onTertiaryContainer: const Color(0xFF065F46),
          error: const Color(0xFFDC2626), // Crimson Red 600
          onError: const Color(0xFFFFFFFF),
          errorContainer: const Color(0xFFFEE2E2),
          onErrorContainer: const Color(0xFF991B1B),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF0F172A), // Slate 900
          surfaceContainerHighest: const Color(0xFFF1F5F9), // Slate 100
          onSurfaceVariant: const Color(0xFF334155), // Slate 700
          outline: const Color(0xFF94A3B8), // Slate 400
          outlineVariant: const Color(0xFFCBD5E1), // Slate 300
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Tactical Neon Cyan — High-contrast telemetry dark theme
  static ThemeData get darkTheme {
    const seedColor = Color(0xFF00E5FF); // Neon cyan / FPV telemetry
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF121820),
          surfaceContainerHighest: const Color(0xFF1E2632),
          primary: const Color(0xFF00E5FF),
          onPrimary: const Color(0xFF0D1117),
          primaryContainer: const Color(0xFF00363D),
          onPrimaryContainer: const Color(0xFF00E5FF),
          secondary: const Color(0xFFFFB300), // Amber highlight
          onSecondary: const Color(0xFF0D1117),
          secondaryContainer: const Color(0xFF3E2800),
          onSecondaryContainer: const Color(0xFFFFD54F),
          tertiary: const Color(0xFF00E676), // Green status
          onTertiary: const Color(0xFF0D1117),
          tertiaryContainer: const Color(0xFF003816),
          onTertiaryContainer: const Color(0xFF69F0AE),
          error: const Color(0xFFFF5252),
          onError: const Color(0xFF0D1117),
          errorContainer: const Color(0xFF4C0F0F),
          onErrorContainer: const Color(0xFFFF8A80),
          onSurface: const Color(0xFFECEFF1),
          onSurfaceVariant: const Color(0xFFB0BEC5),
          outline: const Color(0xFF607D8B),
          outlineVariant: const Color(0xFF2A3441),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 2,
        shadowColor: const Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
