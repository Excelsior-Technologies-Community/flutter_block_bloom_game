import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, AAA arcade/cyber-styled gaming progress bar with:
/// - Smooth 1-100% digital HUD counter
/// - Dynamic loading phase status subtitles
/// - Protected capsule track frame (strict clipping prevents border collapse or overflow at 100%)
/// - Glowing multi-stop neon gradient fill
/// - Continuous glossy light shimmer sweep
/// - Diagonal arcade energy stripe overlay
/// - Leading spark flare at the progress tip (cleanly docked before reaching border)
/// - Cybernetic glassmorphic frame with glowing neon border
class GamingLoadingBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double? width;
  final String? statusText;

  const GamingLoadingBar({
    super.key,
    required this.progress,
    this.width,
    this.statusText,
  });

  @override
  State<GamingLoadingBar> createState() => _GamingLoadingBarState();
}

class _GamingLoadingBarState extends State<GamingLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _getDefaultStatus(double p) {
    if (p < 0.22) return 'INITIALIZING BLOOM CORE...';
    if (p < 0.48) return 'LOADING GARDEN WORLDS...';
    if (p < 0.74) return 'SUMMONING GEM BLOCKS...';
    if (p < 0.94) return 'SYNCING PLAYER PROFILE...';
    return 'READY TO BLOOM!';
  }

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = widget.progress.clamp(0.0, 1.0);
    final int percentInt = (clampedProgress * 100).toInt().clamp(1, 100);
    final String currentStatus = widget.statusText ?? _getDefaultStatus(clampedProgress);
    final bool isCompleted = percentInt >= 100;

    return SizedBox(
      width: widget.width ?? 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top HUD Row: Dynamic Status Message & Neon Digital Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: Pulsing status indicator + status text
                Expanded(
                  child: Row(
                    children: [
                      // Pulsing mini diamond icon
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final pulse = (math.sin(_shimmerController.value * 2 * math.pi) + 1) / 2;
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                const Color(0xFF00FFC2),
                                const Color(0xFFFFD700),
                                pulse,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FFC2).withValues(alpha: 0.8),
                                  blurRadius: 6 + (pulse * 4),
                                  spreadRadius: 1 + pulse,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Flexible(
                        child: Text(
                          currentStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.92),
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right: Big Glowing Numeric Counter (1% - 100%)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$percentInt',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isCompleted
                            ? const Color(0xFF00FFC2)
                            : const Color(0xFFFFE600),
                        shadows: [
                          Shadow(
                            color: isCompleted
                                ? const Color(0xFF00FFC2).withValues(alpha: 0.9)
                                : const Color(0xFFFFC800).withValues(alpha: 0.9),
                            blurRadius: 12,
                          ),
                          const Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '%',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.85),
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main Cyber Gaming Progress Bar (Rigid container geometry to prevent border collapse)
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const trackHeight = 24.0;
              const borderWidth = 1.6;
              const innerPadding = 2.5;

              // Available width strictly inside the border and padding
              final innerWidth = math.max(
                0.0,
                trackWidth - (borderWidth * 2) - (innerPadding * 2),
              );
              final innerHeight = trackHeight - (borderWidth * 2) - (innerPadding * 2);
              final innerRadius = innerHeight / 2;

              // Fill width strictly bounded to innerWidth (never exceeds or breaks the outer border)
              final fillWidth = (innerWidth * clampedProgress).clamp(0.0, innerWidth);

              return Container(
                height: trackHeight,
                width: trackWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                  // Outer cyber glow & depth drop shadow
                  boxShadow: [
                    BoxShadow(
                      color: isCompleted
                          ? const Color(0xFF00FFC2).withValues(alpha: 0.50)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.30),
                      blurRadius: isCompleted ? 18 : 14,
                      spreadRadius: isCompleted ? 2 : 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  // Multi-layered cyber frame border (intact and preserved at 100%)
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF00FFC2).withValues(alpha: 0.95)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.80),
                    width: borderWidth,
                  ),
                  // Deep translucent dark gaming glass background
                  color: const Color(0xFF060B18).withValues(alpha: 0.92),
                ),
                padding: const EdgeInsets.all(innerPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Subdued inner background track
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF030712),
                        ),
                      ),

                      // Filled Progress Bar (bounded strictly inside innerWidth)
                      if (fillWidth > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: fillWidth,
                          child: Stack(
                            children: [
                              // Radiant Gaming Gradient
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF00D2FF), // Neon cyan
                                        Color(0xFF00F5A0), // Vivid emerald
                                        Color(0xFFFFB703), // Radiant amber gold
                                        Color(0xFFFF007A), // Cyber magenta
                                      ],
                                      stops: [0.0, 0.38, 0.74, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Arcade Diagonal Energy Hatch Pattern
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _GamingStripePainter(
                                    stripeColor: Colors.black.withValues(alpha: 0.18),
                                  ),
                                ),
                              ),

                              // Continuous Gloss Shimmer / Light Beam Sweep
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    final shimmerPos = _shimmerController.value;
                                    return ShaderMask(
                                      blendMode: BlendMode.screen,
                                      shaderCallback: (bounds) {
                                        final start = -1.0 + (shimmerPos * 3.0);
                                        return LinearGradient(
                                          begin: Alignment(start - 0.4, 0),
                                          end: Alignment(start + 0.4, 0),
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.15),
                                            Colors.white.withValues(alpha: 0.85),
                                            Colors.white.withValues(alpha: 0.15),
                                            Colors.transparent,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      child: Container(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Top glossy 3D highlight bevel line
                              Positioned(
                                top: 1,
                                left: 4,
                                right: 4,
                                height: 2.2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.7),
                                        Colors.white.withValues(alpha: 0.15),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Leading Edge Neon Spark Orb (Glow flare at progress tip, cleanly hidden when complete)
                      if (clampedProgress > 0.04 && clampedProgress < 0.98)
                        Positioned(
                          left: (fillWidth - 8).clamp(0.0, innerWidth - 12),
                          top: (innerHeight - 10) / 2,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              final sparkPulse =
                                  (math.sin(_shimmerController.value * 2 * math.pi) + 1) / 2;
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFC2).withValues(alpha: 0.95),
                                      blurRadius: 8 + (sparkPulse * 4),
                                      spreadRadius: 1 + sparkPulse,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Bottom Tech HUD Footer: Cyber brackets & Version status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '◄ BLOOM ENGINE ►',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  isCompleted ? 'SYSTEM ONLINE 100%' : 'LOADING MODULES',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: isCompleted
                        ? const Color(0xFF00FFC2).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for futuristic diagonal tech stripes inside the progress track
class _GamingStripePainter extends CustomPainter {
  final Color stripeColor;

  _GamingStripePainter({required this.stripeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const step = 8.5;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.75, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GamingStripePainter oldDelegate) {
    return oldDelegate.stripeColor != stripeColor;
  }
}
