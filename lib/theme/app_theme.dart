import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  /// Esquema de cores base (claro)
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    surface: AppColors.background,
    background: AppColors.background,
    onPrimary: AppColors.textLight,
    onSurface: AppColors.textDark,
    onBackground: AppColors.textDark,
  );

  /// Esquema de cores base (escuro) – opcional
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  );

  /// Tema claro
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ⬇️ AQUI é CardThemeData (não CardTheme)
      cardTheme: CardThemeData(
        color: AppColors.background.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.20)),
        ),
        margin: const EdgeInsets.all(0),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
      ),

      iconTheme: const IconThemeData(color: AppColors.textDark),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.textDark.withOpacity(0.08),
        thickness: 1,
      ),
    );
  }

  /// Tema escuro (opcional)
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkScheme,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(elevation: 0),
      cardTheme: const CardThemeData(), // usa defaults do esquema escuro
    );
  }
}
