import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const green = Color(0xFF237A57);
  static const lightGreen = Color(0xFFB9DCA6);
  static const cream = Color(0xFFFFF6E8);
  static const peach = Color(0xFFFFAA5B);
  static const coral = Color(0xFFE76F60);
  static const ink = Color(0xFF183029);
  static const radius = 18.0;
  static ThemeData create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(seedColor: green, brightness: brightness).copyWith(
          primary: dark ? const Color(0xFF9BD8B8) : green,
          onPrimary: dark ? const Color(0xFF073823) : Colors.white,
          secondary: dark ? const Color(0xFFFFBF83) : peach,
          onSecondary: dark ? const Color(0xFF4A2600) : const Color(0xFF402000),
          tertiary: dark ? const Color(0xFFFFB4AA) : coral,
          onTertiary: dark ? const Color(0xFF5F160F) : Colors.white,
          error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFA6372E),
          surface: dark ? const Color(0xFF111916) : cream,
          onSurface: dark ? const Color(0xFFF2F4EF) : ink,
          surfaceContainerLowest: dark ? const Color(0xFF0C1210) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF19231F)
              : const Color(0xFFFFFBF4),
          surfaceContainer: dark
              ? const Color(0xFF202D27)
              : const Color(0xFFF7EEDC),
          surfaceContainerHighest: dark
              ? const Color(0xFF314139)
              : const Color(0xFFE4EFD9),
          onSurfaceVariant: dark
              ? const Color(0xFFBAC5BB)
              : const Color(0xFF53645C),
          outline: dark ? const Color(0xFF7B8D83) : const Color(0xFF74857C),
          outlineVariant: dark
              ? const Color(0xFF3E5147)
              : const Color(0xFFD3DDD3),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'NotoSansArabic',
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            headlineMedium: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            titleLarge: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            bodyLarge: const TextStyle(fontSize: 16, height: 1.55),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.55),
          )
          .apply(
            fontFamily: 'NotoSansArabic',
            bodyColor: colors.onSurface,
            displayColor: colors.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: dark ? 0 : 1,
        shadowColor: green.withValues(alpha: .10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: dark
            ? const Color(0xFF294F3D)
            : lightGreen.withValues(alpha: .62),
        elevation: 2,
        height: 76,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colors.outlineVariant),
        selectedColor: colors.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
    );
  }
}
