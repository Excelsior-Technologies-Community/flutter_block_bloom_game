import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';

class GlossyGameButton extends StatefulWidget {
  const GlossyGameButton({
    super.key,
    required this.text,
    required this.topColor,
    required this.bottomColor,
    required this.textColor,
    required this.onPressed,
    this.icon,
    this.fontSize = 20.0,
    this.height = 56.0,
    this.width,
    this.borderGradient,
    this.borderRadius,
  });

  final String text;
  final Color topColor;
  final Color bottomColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double fontSize;
  final double height;
  final double? width;
  final Gradient? borderGradient;
  final double? borderRadius;

  // Preset Factory Constructors matching exact specifications
  factory GlossyGameButton.green({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    double height = 44.0,
    double width = 126.0,
    double fontSize = 15.0,
    Widget? icon,
  }) {
    return GlossyGameButton(
      key: key,
      text: text,
      topColor: const Color(0xFF94C745),
      bottomColor: const Color(0xFF1A3C0E),
      textColor: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      height: height,
      width: width,
      onPressed: onPressed,
      icon: icon,
    );
  }

  factory GlossyGameButton.play({
    Key? key,
    String text = 'PLAY',
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
  }) {
    return GlossyGameButton(
      key: key,
      text: text,
      // Previous colors: topColor: Color(0xFFFD9482), bottomColor: Color(0xFF7C0061)
      topColor: const Color(0xFF7E276A),
      bottomColor: const Color(0xFFF19AD3),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 20.0,
      height: height,
      width: width,
      onPressed: onPressed,
      icon: Image.asset(
        'assets/play_icon.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  factory GlossyGameButton.dailyGarden({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
  }) {
    return GlossyGameButton(
      key: key,
      text: 'DAILY GARDEN',
      // Previous colors: topColor: Color(0xFFCFF6FF), bottomColor: Color(0xFF0096B7)
      topColor: const Color(0xFF277A7E),
      bottomColor: const Color(0xFF9AEDF1),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 18.0,
      height: height,
      width: width,
      onPressed: onPressed,
      icon: Image.asset(
        'assets/calendar_icon.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.calendar_today_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  factory GlossyGameButton.garden({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
  }) {
    return GlossyGameButton(
      key: key,
      text: 'GARDEN',
      // Previous colors: topColor: Color(0xFFE4FFCF), bottomColor: Color(0xFF91D872)
      topColor: const Color(0xFF527E27),
      bottomColor: const Color(0xFFDBF19A),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 20.0,
      height: height,
      width: width,
      onPressed: onPressed,
      icon: Image.asset(
        'assets/garden_icon.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.eco_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  factory GlossyGameButton.trophy({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
    double fontSize = 20.0,
  }) {
    return GlossyGameButton(
      key: key,
      text: 'LEADERBOARD',
      topColor: const Color(0xFFC7AD45),
      bottomColor: const Color(0xFF4A330F),
      textColor: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      height: height,
      width: width,
      borderGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7E7A27),
          Color(0xFFF1E59A),
        ],
      ),
      onPressed: onPressed,
      icon: Image.asset(
        'assets/trophy_icon.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFFFD700),
          size: 26,
        ),
      ),
    );
  }

  factory GlossyGameButton.leaderboard({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
    double fontSize = 20.0,
  }) =>
      GlossyGameButton.trophy(
        key: key,
        onPressed: onPressed,
        height: height,
        width: width,
        fontSize: fontSize,
      );

  factory GlossyGameButton.settings({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
  }) {
    return GlossyGameButton(
      key: key,
      text: 'SETTINGS',
      // Previous colors: topColor: Color(0xFFFFF4DD), bottomColor: Color(0xFFF2D8A2)
      topColor: const Color(0xFFF4EBBE),
      bottomColor: const Color(0xFFF5F4F3),
      textColor: const Color(0xFF725726),
      fontSize: 20.0,
      height: height,
      width: width,
      onPressed: onPressed,
      icon: Image.asset(
        'assets/settings_icon.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.settings_outlined,
          color: Color(0xFF725726),
          size: 26,
        ),
      ),
    );
  }

  factory GlossyGameButton.profile({
    Key? key,
    required VoidCallback? onPressed,
    double height = 56.0,
    double? width,
    double fontSize = 20.0,
    double? borderRadius,
  }) {
    return GlossyGameButton(
      key: key,
      text: 'PROFILE',
      topColor: const Color(0xFFA7B1F2),
      bottomColor: const Color(0xFF353EBF),
      textColor: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      height: height,
      width: width,
      borderRadius: borderRadius,
      borderGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFA19BEB),
          Color(0xFFD5D6FF),
        ],
      ),
      onPressed: onPressed,
      icon: Image.asset(
        'assets/profile.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        color: Colors.white,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.account_circle,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  @override
  State<GlossyGameButton> createState() => _GlossyGameButtonState();
}

class _GlossyGameButtonState extends State<GlossyGameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final isPressedNow = _isPressed && isEnabled;
    final double radius = widget.borderRadius ?? (widget.height / 2);

    return GestureDetector(
      onTapDown: (_) {
        if (isEnabled) {
          setState(() => _isPressed = true);
          AudioService.instance.playClickSound();
        }
      },
      onTapUp: (_) {
        if (isEnabled) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (isEnabled) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: isPressedNow ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: CustomPaint(
          foregroundPainter: widget.borderGradient != null
              ? _GradientBorderPainter(
                  gradient: widget.borderGradient!,
                  strokeWidth: 1.5,
                  radius: radius,
                )
              : null,
          child: Container(
            height: widget.height,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.topColor, widget.bottomColor],
              ),
              border: widget.borderGradient != null
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.5,
                    ),
              boxShadow: [
                BoxShadow(
                  color: widget.bottomColor.withValues(alpha: isPressedNow ? 0.2 : 0.4),
                  blurRadius: isPressedNow ? 4 : 10,
                  offset: Offset(0, isPressedNow ? 2 : 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1.5),
              child: Stack(
                children: [
                  // Top Glossy Sheen Overlay Arc
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.height * 0.48,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.elliptical(200, 30),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.60),
                            Colors.white.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Button Content (Icon + Text)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.text,
                            style: GoogleFonts.chakraPetch(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w700,
                              color: widget.textColor,
                              letterSpacing: 0.8,
                            ),
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
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double radius;

  _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius - strokeWidth / 2),
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
