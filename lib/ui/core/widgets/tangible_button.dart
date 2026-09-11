import 'package:flutter/material.dart';
import 'package:block_bloom/ui/core/theme/app_colors.dart';
import 'package:block_bloom/data/services/audio_service.dart';

class TangibleButton extends StatefulWidget {
  const TangibleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.height = 56,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final double height;

  @override
  State<TangibleButton> createState() => _TangibleButtonState();
}

class _TangibleButtonState extends State<TangibleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onPressed != null;
    final isPressedNow = _isPressed && isInteractive;

    final Color buttonBg = widget.isSecondary 
        ? AppColors.secondaryButtonBg 
        : AppColors.buttonBg;

    final Color textColor = widget.isSecondary
        ? AppColors.secondaryButtonText
        : AppColors.buttonText;

    return GestureDetector(
      onTapDown: (_) {
        if (isInteractive) {
          setState(() => _isPressed = true);
          AudioService.instance.playClickSound();
        }
      },
      onTapUp: (_) {
        if (isInteractive) {
          setState(() => _isPressed = false);
          if (widget.onPressed != null) widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (isInteractive) setState(() => _isPressed = false);
      },
      child: Opacity(
        opacity: isPressedNow ? 0.8 : 1.0,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSecondary ? AppColors.gridLines : AppColors.buttonBg,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isPressedNow ? 0.02 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text.toUpperCase(),
            style: TextStyle(
              fontFamily: 'BebasNeue',
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
