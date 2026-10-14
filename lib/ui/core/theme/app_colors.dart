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
    Color(0xFFDD2C2C), // 1: Ruby Crimson Red
    Color(0xFFABC90F), // 2: Chartreuse Lime Green
    Color(0xFFFFAA1E), // 3: Tangerine Amber
    Color(0xFF019262), // 4: Jade Emerald Green
    Color(0xFF60D612), // 5: Vibrant Neon Green
    Color(0xFFFF8899), // 6: Coral Peach Pink
    Color(0xFFC85FFF), // 7: Royal Violet Purple
    Color(0xFFFFB222), // 8: Golden Honey
    Color(0xFFF406B1), // 9: Vivid Fuchsia Magenta
    Color(0xFF007AFF), // 10: Azure Electric Blue
    Color(0xFF04AFAE), // 11: Aqua Mint Teal
    Color(0xFFDD2C52), // 12: Ruby Crimson Rose
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

