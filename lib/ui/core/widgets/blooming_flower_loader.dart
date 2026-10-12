import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A 5-petal ("plates") blooming flower loading indicator.
///
/// Animation choreography:
/// 1. Flower begins with all 5 petals open.
/// 2. Petals fold/close ONE BY ONE in sequential clockwise order (Petal 1 -> 2 -> 3 -> 4 -> 5).
/// 3. Brief bud pause where the golden flower heart pulses.
/// 4. Petals bloom/open ONE BY ONE in sequential order (Petal 1 -> 2 -> 3 -> 4 -> 5)
///    with an organic spring/bloom easing curve.
/// 5. Brief full bloom celebration with radiant petals before repeating.
class BloomingFlowerLoader extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color? petalStartColor;
  final Color? petalEndColor;
  final Color? centerColor;
  final bool slowRotation;

  const BloomingFlowerLoader({
    super.key,
    this.size = 64.0,
    this.duration = const Duration(milliseconds: 2200),
    this.petalStartColor,
    this.petalEndColor,
    this.centerColor,
    this.slowRotation = true,
  });

  @override
  State<BloomingFlowerLoader> createState() => _BloomingFlowerLoaderState();
}

class _BloomingFlowerLoaderState extends State<BloomingFlowerLoader>
    with TickerProviderStateMixin {
  late AnimationController _bloomController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _bloomController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    if (widget.slowRotation) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BloomingFlowerLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _bloomController.duration = widget.duration;
    }
    if (oldWidget.slowRotation != widget.slowRotation) {
      if (widget.slowRotation) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _bloomController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bloomController, _rotationController]),
      builder: (context, child) {
        final double rotationAngle =
            widget.slowRotation ? _rotationController.value * 2 * math.pi : 0.0;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BloomingFlowerPainter(
              bloomProgress: _bloomController.value,
              rotationAngle: rotationAngle,
              petalStartColor: widget.petalStartColor ?? const Color(0xFFFF3366),
              petalEndColor: widget.petalEndColor ?? const Color(0xFFFF94B8),
              centerColor: widget.centerColor ?? const Color(0xFFFFC107),
            ),
          ),
        );
      },
    );
  }
}

class _BloomingFlowerPainter extends CustomPainter {
  final double bloomProgress; // 0.0 to 1.0
  final double rotationAngle;
  final Color petalStartColor;
  final Color petalEndColor;
  final Color centerColor;

  static const int petalCount = 5;

  _BloomingFlowerPainter({
    required this.bloomProgress,
    required this.rotationAngle,
    required this.petalStartColor,
    required this.petalEndColor,
    required this.centerColor,
  });

  /// Computes the open/close state of petal [index] (0..4).
  /// Returns a double where:
  /// 1.0 = fully bloomed/open
  /// 0.0 = fully closed/folded inward
  double _getPetalOpenFactor(int index, double progress) {
    // Timeline intervals:
    // 0.00 - 0.05: Hold all 5 open
    // 0.05 - 0.45: Closing 1 by 1 (staggered)
    // 0.45 - 0.53: Hold all 5 closed (bud state)
    // 0.53 - 0.93: Opening 1 by 1 (staggered)
    // 0.93 - 1.00: Hold all 5 open

    const double closeStartBase = 0.05;
    const double closeDuration = 0.14;
    const double closeStagger = 0.055;

    const double openStartBase = 0.53;
    const double openDuration = 0.15;
    const double openStagger = 0.055;

    final double petalCloseStart = closeStartBase + (index * closeStagger);
    final double petalCloseEnd = petalCloseStart + closeDuration;

    final double petalOpenStart = openStartBase + (index * openStagger);
    final double petalOpenEnd = petalOpenStart + openDuration;

    // 1. Initial open hold
    if (progress < petalCloseStart) {
      return 1.0;
    }

    // 2. Petal closing phase: 1.0 -> 0.0
    if (progress >= petalCloseStart && progress <= petalCloseEnd) {
      final double t =
          ((progress - petalCloseStart) / (petalCloseEnd - petalCloseStart))
              .clamp(0.0, 1.0);
      // Smooth inward folding ease curve
      final double eased = Curves.easeInOutCubic.transform(t);
      return (1.0 - eased).clamp(0.0, 1.0);
    }

    // 3. Bud / closed hold
    if (progress > petalCloseEnd && progress < petalOpenStart) {
      return 0.0;
    }

    // 4. Petal opening phase: 0.0 -> 1.0 (with slight lively organic spring bloom)
    if (progress >= petalOpenStart && progress <= petalOpenEnd) {
      final double t =
          ((progress - petalOpenStart) / (petalOpenEnd - petalOpenStart))
              .clamp(0.0, 1.0);
      final double eased = Curves.easeOutBack.transform(t);
      return eased.clamp(0.0, 1.15);
    }

    // 5. Final full blossom hold
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2;
    final Offset center = Offset(cx, cy);

    // Dynamic measurements
    final double centerDiskRadius = radius * 0.26;
    final double maxPetalLength = radius * 0.92;
    final double maxPetalWidth = radius * 0.58;

    // Pulse for center bud when petals are folded
    final bool isBudPhase = bloomProgress >= 0.40 && bloomProgress <= 0.60;
    final double budPulse = isBudPhase
        ? 1.0 + 0.12 * math.sin((bloomProgress - 0.40) / 0.20 * math.pi)
        : 1.0;

    // Ambient background soft glow behind flower
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          petalStartColor.withValues(alpha: 0.25),
          petalEndColor.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));
    canvas.drawCircle(center, radius * 1.1, glowPaint);

    // Draw the 5 Petals
    for (int i = 0; i < petalCount; i++) {
      final double openFactor = _getPetalOpenFactor(i, bloomProgress);

      // If petal is completely folded in, don't draw it
      if (openFactor <= 0.01) continue;

      // Base angle: Petal 0 starts pointing directly UP (-pi/2)
      final double baseAngle =
          (-math.pi / 2) + (i * (2 * math.pi / petalCount)) + rotationAngle;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(baseAngle);

      _drawSinglePetal(
        canvas: canvas,
        openFactor: openFactor,
        maxLength: maxPetalLength,
        maxWidth: maxPetalWidth,
        centerDiskRadius: centerDiskRadius,
      );

      canvas.restore();
    }

    // Draw Center Pistil / Golden Pollen Core (matching game_flower.png)
    _drawCenterCore(
      canvas: canvas,
      center: center,
      diskRadius: centerDiskRadius * budPulse,
    );
  }

  void _drawSinglePetal({
    required Canvas canvas,
    required double openFactor,
    required double maxLength,
    required double maxWidth,
    required double centerDiskRadius,
  }) {
    // Current animated length and width of the petal
    // Petal grows/shrinks radially and narrows/widens naturally
    final double clampedFactor = openFactor.clamp(0.0, 1.15);
    final double petalLength = maxLength * clampedFactor;
    final double petalWidth = maxWidth * (0.25 + 0.75 * clampedFactor.clamp(0.0, 1.0));
    final double baseOffset = centerDiskRadius * 0.45 * clampedFactor.clamp(0.0, 1.0);

    // Build organic rounded petal shape (pointing along positive Y axis in local frame)
    final Path petalPath = Path();
    petalPath.moveTo(0, baseOffset);

    // Left outward curve to shoulder then tip
    petalPath.cubicTo(
      -petalWidth * 0.52,
      baseOffset + petalLength * 0.32,
      -petalWidth * 0.50,
      baseOffset + petalLength * 0.76,
      -petalWidth * 0.12,
      baseOffset + petalLength * 0.98,
    );

    // Soft rounded petal tip
    petalPath.quadraticBezierTo(
      0,
      baseOffset + petalLength,
      petalWidth * 0.12,
      baseOffset + petalLength * 0.98,
    );

    // Right inward curve from tip back to base
    petalPath.cubicTo(
      petalWidth * 0.50,
      baseOffset + petalLength * 0.76,
      petalWidth * 0.52,
      baseOffset + petalLength * 0.32,
      0,
      baseOffset,
    );
    petalPath.close();

    // 1. Soft Drop Shadow under petal
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * clampedFactor.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.save();
    canvas.translate(0, 1.5);
    canvas.drawPath(petalPath, shadowPaint);
    canvas.restore();

    // 2. Radiant Blossom Gradient Fill
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          petalStartColor, // Deep vibrant cherry/rose base
          Color.lerp(petalStartColor, petalEndColor, 0.45)!,
          petalEndColor, // Soft bright blossom pink tip
          const Color(0xFFFFF0F5), // Lightest highlight edge
        ],
        stops: const [0.0, 0.35, 0.85, 1.0],
      ).createShader(
        Rect.fromLTWH(
          -petalWidth / 2,
          baseOffset,
          petalWidth,
          petalLength,
        ),
      );
    canvas.drawPath(petalPath, fillPaint);

    // 3. Delicate Inner Sheen / Translucent Petal Vein
    final Path highlightPath = Path();
    highlightPath.moveTo(0, baseOffset + petalLength * 0.15);
    highlightPath.quadraticBezierTo(
      -petalWidth * 0.08,
      baseOffset + petalLength * 0.55,
      0,
      baseOffset + petalLength * 0.82,
    );

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40 * clampedFactor.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);

    // 4. Fine Petal Border Line for clean definition
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFC2185B).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(petalPath, borderPaint);
  }

  void _drawCenterCore({
    required Canvas canvas,
    required Offset center,
    required double diskRadius,
  }) {
    // 1. Deep magenta / ruby outer backing ring (matching assets/game_flower.png)
    final Paint outerRingPaint = Paint()
      ..color = const Color(0xFF5A002C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, diskRadius, outerRingPaint);

    // 2. Outer ring shadow
    final Paint ringShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, diskRadius, ringShadowPaint);

    // 3. Golden Amber Pollen Core
    final double innerRadius = diskRadius * 0.72;
    final Paint goldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF9C4), // Bright light gold
          centerColor, // Amber / warm gold
          const Color(0xFFFF8F00), // Rich amber edge
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: innerRadius),
      );
    canvas.drawCircle(center, innerRadius, goldPaint);

    // 4. Subtle pollen stamens / dots inside center
    final double stamenOrbit = innerRadius * 0.55;
    final Paint stamenPaint = Paint()
      ..color = const Color(0xFF8D4B00).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final double angle = (i * 2 * math.pi / 5);
      final double sx = center.dx + stamenOrbit * math.cos(angle);
      final double sy = center.dy + stamenOrbit * math.sin(angle);
      canvas.drawCircle(Offset(sx, sy), innerRadius * 0.16, stamenPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BloomingFlowerPainter oldDelegate) {
    return oldDelegate.bloomProgress != bloomProgress ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.petalStartColor != petalStartColor ||
        oldDelegate.petalEndColor != petalEndColor ||
        oldDelegate.centerColor != centerColor;
  }
}
