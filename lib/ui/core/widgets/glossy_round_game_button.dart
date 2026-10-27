import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// Circular Glossy Game Button
///
/// Designed to match the round glossy green buttons from the reference image:
/// - Exact spherical glossy jelly button with deep dark teal/emerald border
/// - Multi-stop lime-to-forest-green gradient with top specular highlights
/// - Inset 3D embossed icon styling
/// - Smooth tactile scale bounce animation on press with sound and haptics
class GlossyRoundGameButton extends StatefulWidget {
  final Widget? icon;
  final String? imageAsset;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  const GlossyRoundGameButton({
    super.key,
    this.icon,
    this.imageAsset,
    required this.onPressed,
    required this.tooltip,
    this.size = 62.0,
  });

  /// Factory for the Shop button (Left down - exact reference image shopping cart asset)
  factory GlossyRoundGameButton.shop({
    Key? key,
    required VoidCallback? onPressed,
    double size = 62.0,
  }) {
    return GlossyRoundGameButton(
      key: key,
      size: size,
      tooltip: 'Shop',
      onPressed: onPressed,
      imageAsset: 'assets/shop_button_glossy.png',
    );
  }

  /// Factory for the Garden button (Right side - matching glossy green sphere with garden house)
  factory GlossyRoundGameButton.garden({
    Key? key,
    required VoidCallback? onPressed,
    double size = 62.0,
  }) {
    return GlossyRoundGameButton(
      key: key,
      size: size,
      tooltip: 'Garden',
      onPressed: onPressed,
      imageAsset: 'assets/garden_button_glossy.png',
    );
  }

  /// Factory for Trophy / Leaderboard (matching middle round button in reference image)
  factory GlossyRoundGameButton.leaderboard({
    Key? key,
    required VoidCallback? onPressed,
    double size = 62.0,
  }) {
    return GlossyRoundGameButton(
      key: key,
      size: size,
      tooltip: 'Leaderboard',
      onPressed: onPressed,
      imageAsset: 'assets/trophy_button_glossy.png',
    );
  }

  /// Factory for Settings (matching left round button in reference image)
  factory GlossyRoundGameButton.settings({
    Key? key,
    required VoidCallback? onPressed,
    double size = 62.0,
  }) {
    return GlossyRoundGameButton(
      key: key,
      size: size,
      tooltip: 'Settings',
      onPressed: onPressed,
      imageAsset: 'assets/settings_button_glossy.png',
    );
  }

  @override
  State<GlossyRoundGameButton> createState() => _GlossyRoundGameButtonState();
}

class _GlossyRoundGameButtonState extends State<GlossyRoundGameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final double size = widget.size;

    return Tooltip(
      message: widget.tooltip,
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
            HapticFeedback.lightImpact();
            widget.onPressed?.call();
          }
        },
        onTapCancel: () {
          if (isEnabled) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: size,
            height: size,
            child: widget.imageAsset != null
                ? Image.asset(
                    widget.imageAsset!,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        widget.icon ?? const SizedBox.shrink(),
                  )
                : widget.icon ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
