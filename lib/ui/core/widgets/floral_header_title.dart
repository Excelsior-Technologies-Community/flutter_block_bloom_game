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

  /// Upward curve arch height in logical pixels
  final double curveAmount;

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
    final characters = cleanTitle.split('');
    final totalChars = characters.length;

    Widget buildMainArchedText() {
      const double refHalfSpan = 5.5;

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(totalChars, (i) {
          final centerIndex = (totalChars - 1) / 2.0;
          final xFromCenter = i - centerIndex;

          // Normalized position t relative to Daily Garden's curve radius
          final t = totalChars > 1 ? (xFromCenter / refHalfSpan) : 0.0;

          // Quadratic upward displacement for smooth arch curve plus vertical offset
          final dy = ((1.0 - (t * t)) * -curveAmount) + verticalOffset;

          // Rotational tilt matching Daily Garden's exact curve slope
          final angle = t * 0.18;

          if (characters[i] == ' ') {
            return SizedBox(width: fontSize * 0.35);
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
                    characters[i],
                    style: GoogleFonts.chakraPetch(
                      fontSize: fontSize,
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
      centerTitleWidget = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Little Title (e.g. 'DAILY')
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              topTitle!.trim().toUpperCase(),
              style: GoogleFonts.chakraPetch(
                fontSize: topFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4.0,
                shadows: [
                  Shadow(
                    color: shadowColor,
                    offset: const Offset(1.0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          buildMainArchedText(),
        ],
      );
    } else {
      centerTitleWidget = buildMainArchedText();
    }

    return Row(
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
    );
  }
}
