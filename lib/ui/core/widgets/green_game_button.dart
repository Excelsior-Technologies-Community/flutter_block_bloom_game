import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// A reusable glossy green game button widget designed according to Figma specifications:
/// - Height: 44px
/// - Default Width: 126px (or custom width / double.infinity)
/// - Radius: 12px
/// - Padding: 3px
/// - Gradient: Top #94C745 to Bottom #1A3C0E
/// - Shadow: 25% Black
class GreenGameButton extends StatefulWidget {
  const GreenGameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 126.0,
    this.height = 44.0,
    this.borderRadius = 12.0,
    this.fontSize = 15.0,
    this.textColor = Colors.white,
    this.icon,
  });

  /// Button label text (e.g. 'RESUME', 'RESTART', 'HOME')
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button width (defaults to Figma 126px spec, set to double.infinity for fill)
  final double? width;

  /// Button height (defaults to Figma 44px spec)
  final double height;

  /// Border radius (defaults to Figma 12px spec)
  final double borderRadius;

  /// Text font size
  final double fontSize;

  /// Text color
  final Color textColor;

  /// Optional icon to display before the text
  final Widget? icon;

  @override
  State<GreenGameButton> createState() => _GreenGameButtonState();
}

class _GreenGameButtonState extends State<GreenGameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final isPressedNow = _isPressed && isEnabled;

    // Figma Gradient colors: Top #94C745, Bottom #1A3C0E
    const topGradient = Color(0xFF94C745);
    const bottomGradient = Color(0xFF1A3C0E);

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
        if (isEnabled) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedScale(
        scale: isPressedNow ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(3.0), // Figma padding: 3px
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topGradient, bottomGradient],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              // Figma Shadow: #000000 25%
              BoxShadow(
                color: Colors.black.withValues(alpha: isPressedNow ? 0.15 : 0.25),
                blurRadius: isPressedNow ? 3 : 6,
                offset: Offset(0, isPressedNow ? 2 : 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - 2),
            child: Stack(
              children: [
                // Top Gloss Sheen Arc Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.elliptical(120, 20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),

                // Button Content (Optional Icon + Bold Text)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 6),
                        ],
                        Text(
                          widget.text.toUpperCase(),
                          style: GoogleFonts.chakraPetch(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w800,
                            color: widget.textColor,
                            letterSpacing: 1.0,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1.5),
                                blurRadius: 2,
                              ),
                            ],
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
    );
  }
}
