import 'package:flutter/material.dart';

abstract final class ExampleAppTheme {
  static const Color _seedLight = Color(0xFF4B5563);
  static const Color _seedDark = Color(0xFF9CA3AF);
  static const Color _accent = Color(0xFF64748B);

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedLight,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = base.copyWith(
      tertiary: _accent,
      onTertiary: const Color(0xFF1C1917),
    );
    return _buildTheme(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedDark,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = base.copyWith(
      tertiary: _accent,
      onTertiary: const Color(0xFF1C1917),
    );
    return _buildTheme(scheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final baseText = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    final textTheme = baseText
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 15.5,
            letterSpacing: -0.1,
          ),
          titleSmall: baseText.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: -0.05,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            letterSpacing: -0.5,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
            letterSpacing: -0.05,
          ),
          bodySmall: baseText.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            letterSpacing: -0.05,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: -0.05,
          ),
          labelMedium: baseText.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
            letterSpacing: -0.05,
          ),
        );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF4F5F7)
          : scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(72, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
