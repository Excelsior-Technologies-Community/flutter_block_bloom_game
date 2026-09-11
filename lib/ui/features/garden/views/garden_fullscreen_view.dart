import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// Screen 2: Garden Fullscreen View
/// Uses `SizedBox.expand` & `StackFit.expand` to force 100% full screen background coverage.
/// Matches exact Figma preview image (`view full garden screen`):
/// - Back arrow: `Icons.arrow_back_rounded` (`←`, 20x20px, LinearGradient #FFFFFF to #E9CC70)
/// - Title: `GARDEN FULLSCREEN` (Chakra Petch 22px 600 SemiBold, LinearGradient #FFFFFF to #E9CC70)
/// - Top right glowing moon graphic in the night sky
/// - 100% full screen garden background landscape spanning edge-to-edge.
class GardenFullscreenView extends StatelessWidget {
  const GardenFullscreenView({
    super.key,
    this.backgroundAsset = 'assets/decorate/1.png',
  });

  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001C),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fullscreen Garden Background Image (Fills 100% of device screen height and width)
            Positioned.fill(
              child: Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/splash_img.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (ctx, err, st) => Container(color: const Color(0xFF0F172A)),
                ),
              ),
            ),

            // 2. Transparent Top Header Overlay (Positioned at top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      // Back Arrow Vector (← Icons.arrow_back_rounded, 20x20px, Gradient #FFFFFF to #E9CC70)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          AudioService.instance.playClickSound();
                          Navigator.of(context).pop();
                        },
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Header Title: GARDEN FULLSCREEN (Chakra Petch 22px 600 SemiBold, #FFFFFF to #E9CC70)
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          'GARDEN FULLSCREEN',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: 0.0,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
