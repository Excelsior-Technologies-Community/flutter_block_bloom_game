import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// Animated Glossy Play Button (Border-to-Border, No Outer Shadow)
///
/// Uses the exact, pixel-perfect glossy casual-game artwork asset:
/// - Clean border-to-border rendering: button only, absolutely no square or artificial outer shadows.
/// - Fluid idle breathing pulse animation (scale 1.0 <-> 1.036)
/// - Tactile interactive press-down with audio click and haptic feedback
class AnimatedGlossyPlayButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double height;
  final double? width;

  const AnimatedGlossyPlayButton({
    super.key,
    required this.onPressed,
    this.height = 84.0,
    this.width,
  });

  @override
  State<AnimatedGlossyPlayButton> createState() =>
      _AnimatedGlossyPlayButtonState();
}

class _AnimatedGlossyPlayButtonState extends State<AnimatedGlossyPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Gentle rhythmic breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.036).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final size = MediaQuery.of(context).size;
    final double buttonWidth =
        widget.width ?? math.min(size.width * 0.84, 310.0);
    final double buttonHeight = widget.height;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final double currentScale =
            _isPressed ? 0.92 : _pulseAnimation.value;

        return Transform.scale(
          scale: currentScale,
          child: Tooltip(
            message: 'Play Game',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                if (isEnabled) {
                  setState(() => _isPressed = true);
                  AudioService.instance.playClickSound();
                }
              },
              onTapUp: (_) {
                if (isEnabled) {
                  setState(() => _isPressed = false);
                  HapticFeedback.mediumImpact();
                  widget.onPressed?.call();
                }
              },
              onTapCancel: () {
                if (isEnabled) {
                  setState(() => _isPressed = false);
                }
              },
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                // Border-to-border: Button only, no outer box or shadows
                child: Image.asset(
                  'assets/play_button_glossy.png',
                  width: buttonWidth,
                  height: buttonHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
