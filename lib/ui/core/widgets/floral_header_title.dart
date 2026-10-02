import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable floral header title widget that displays arched curved text
/// flanked symmetrically by pink flowers with green leaves.
class FloralHeaderTitle extends StatelessWidget {
  const FloralHeaderTitle({
    super.key,
    required this.title,
    this.topTitle,
    this.fontSize = 34.0,
    this.topFontSize = 16.0,
    this.flowerSize = 42.0,
    this.curveAmount = 16.0,
    this.topCurveAmount,
    this.topTitleSpacing = -8.0,
    this.verticalOffset = -22.0,
    this.gradientColors = const [
      Color(0xFFFFFFFF),
      Color(0xFFFFC610),
    ],
    this.shadowColor = const Color(0xFF814D00),
    this.letterSpacing = 2.0,
  });

  /// The main title text to display (e.g., 'PAUSE', 'SETTINGS', 'GARDEN', etc.)
  final String title;

  /// Optional top little title text displayed above main title (e.g., 'DAILY')
  final String? topTitle;

  /// Font size for the main header letters
  final double fontSize;

  /// Font size for the top little header text
  final double topFontSize;

  /// Size (width & height) of the side flower assets
  final double flowerSize;

  /// Upward curve arch height in logical pixels for main title
  final double curveAmount;

  /// Optional curve arch height for top title (defaults to curveAmount if null)
  final double? topCurveAmount;

  /// Vertical spacing between top title and main title (negative values reduce gap)
  final double topTitleSpacing;

  /// Additional vertical offset (negative values move text further UP top)
  final double verticalOffset;

  /// Linear gradient colors for title text
  final List<Color> gradientColors;

  /// Drop shadow color for text depth
  final Color shadowColor;

  /// Additional spacing between letters
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim().toUpperCase();

    Widget buildArchedText(String text, double fSize, double curve, double vOffset) {
      final clean = text.trim().toUpperCase();
      final chars = clean.split('');
      final total = chars.length;
      final double refHalfSpan = total > 1 ? math.max(1.5, (total - 1) / 2.0) : 1.0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(total, (i) {
          final centerIndex = (total - 1) / 2.0;
          final xFromCenter = i - centerIndex;
          final t = total > 1 ? (xFromCenter / refHalfSpan) : 0.0;
          final dy = ((1.0 - (t * t)) * -curve) + vOffset;
          final angle = t * 0.22;

          if (chars[i] == ' ') {
            return SizedBox(width: fSize * 0.35);
          }

          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: letterSpacing),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    chars[i],
                    style: GoogleFonts.chakraPetch(
                      fontSize: fSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: shadowColor,
                          offset: const Offset(1.5, 2.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    final hasTopTitle = topTitle != null && topTitle!.trim().isNotEmpty;

    Widget centerTitleWidget;
    if (hasTopTitle) {
      final double positiveGap = topTitleSpacing > 0 ? topTitleSpacing : 0.0;
      final double negativeShift = topTitleSpacing < 0 ? topTitleSpacing : 0.0;

      centerTitleWidget = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Arched Title (e.g. 'LEVEL') - translated DOWN when topTitleSpacing is negative
          Transform.translate(
            offset: Offset(0, -negativeShift),
            child: buildArchedText(
              topTitle!,
              topFontSize > 0 ? topFontSize : fontSize * 0.9,
              topCurveAmount ?? curveAmount,
              0.0,
            ),
          ),
          if (positiveGap > 0) SizedBox(height: positiveGap),
          // Main Arched Title (e.g. 'COMPLETE')
          buildArchedText(cleanTitle, fontSize, curveAmount, 0.0),
        ],
      );
    } else {
      centerTitleWidget = buildArchedText(cleanTitle, fontSize, curveAmount, verticalOffset);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Flower with Green Leaves (Portion 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Transform.rotate(
              angle: -0.15,
              child: Image.asset(
                'assets/flower.png',
                width: flowerSize,
                height: flowerSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  '🌸',
                  style: TextStyle(fontSize: flowerSize * 0.7),
                ),
              ),
            ),
          ),
          SizedBox(width: letterSpacing * 2),

          // Center Title Portion (Portion 2: Top Little Title + Main Arched Title)
          centerTitleWidget,
          SizedBox(width: letterSpacing * 2),

          // Right Flower Portion (Portion 3: Mirrored flower asset)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Transform.scale(
              scaleX: -1,
              child: Transform.rotate(
                angle: -0.15,
                child: Image.asset(
                  'assets/flower.png',
                  width: flowerSize,
                  height: flowerSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    '🌸',
                    style: TextStyle(fontSize: flowerSize * 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
