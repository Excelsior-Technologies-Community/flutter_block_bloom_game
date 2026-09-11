import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFF0FDF4); // Fresh light mint background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color buttonBg = Color(0xFF065F46); // Deep emerald button
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color secondaryButtonBg = Color(0xFFE2E8F0);
  static const Color secondaryButtonText = Color(0xFF0F172A);
  static const Color primary = Color(0xFF059669);
  static const Color headingDark = Color(0xFF064E3B);
  static const Color subtext = Color(0xFF475569);
  static const Color gridLines = Color(0xFFCBD5E1);
  static const Color cardBorder = Color(0xFFA7F3D0);
  static const Color emptyCellBg = Color(0xFFE2E8F0);

  // Dark Theme Game UI Colors (#090027 background, #001834 card background)
  static const Color cardBg = Color(0xFF090027);
  static const Color gameBg = Color(0xFF090027);
  static const Color cardSlotBg = Color(0xFF001834);
  static const Color goldBorder = Color(0xFFFFC800);
  static const Color borderBlue = Color(0xFF1E40AF);

  // Garden Highlights
  static const Color sunflowerGold = Color(0xFFF59E0B);
  static const Color blueHydrangea = Color(0xFF2563EB);
  static const Color roseHibiscus = Color(0xFFDC2626);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4), Color(0xFFE6F4EA)],
  );

  static const List<Color> blockColors = [
    Color(0xFF10B981), // Mint Emerald
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Coral Red
    Color(0xFFF59E0B), // Amber Gold
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Rose Pink
    Color(0xFF84CC16), // Lime Green
  ];
}

class AppTheme {
  static ThemeData get light => ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'BebasNeue',
            ),
      );
}

