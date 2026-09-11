import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Garden Shield Badge Widget
/// Displays `assets/my_garden_shield.png` with level number inside
/// and stage title + subtitle below it.
class GardenShieldBadge extends StatelessWidget {
  const GardenShieldBadge({
    super.key,
    required this.level,
    required this.stageName,
    required this.description,
  });

  final int level;
  final String stageName;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Golden Shield Image Frame with Level Text Overlay
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/my_garden_shield.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF001834),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFC800), width: 2),
                  ),
                ),
              ),
              Positioned(
                top: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        'GARDEN LEVEL',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        '$level',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Stage Title ("GARDEN HOUSE")
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            stageName.toUpperCase(),
            style: GoogleFonts.chakraPetch(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
