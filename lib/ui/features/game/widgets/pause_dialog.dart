import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/providers.dart';

/// Pause Dialog Overlay matching exact visual specs in design screenshot:
/// - Fullscreen blur backdrop over gameplay screen
/// - Floating arched "PAUSE" title with side flowers
/// - Vertically stacked glossy green buttons (RESUME, RESTART, HOME) without card container
class PauseDialog extends ConsumerWidget {
  const PauseDialog({
    super.key,
    this.onRestart,
    this.onHome,
  });

  final VoidCallback? onRestart;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      elevation: 0,
      child: Stack(
        children: [
          // Fullscreen Backdrop Blur Filter over the gameplay screen
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),

          // Centered Floating Pause Content (Title + Stacked Green Buttons)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Arched Header Title with Flowers
                  const FloralHeaderTitle(
                    title: 'PAUSE',
                    fontSize: 36.0,
                    flowerSize: 44.0,
                    curveAmount: 16.0,
                    verticalOffset: -22.0,
                    letterSpacing: 2.0,
                  ),

                  const SizedBox(height: 36),

                  // 1. RESUME Button
                  GreenGameButton(
                    text: 'RESUME',
                    width: 145.0,
                    height: 46.0,
                    fontSize: 16.0,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. RESTART Button
                  GreenGameButton(
                    text: 'RESTART',
                    width: 145.0,
                    height: 46.0,
                    fontSize: 16.0,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onRestart != null) {
                        onRestart!();
                      } else {
                        ref.read(gameViewModelProvider.notifier).resetLevel();
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  // 3. HOME Button
                  GreenGameButton(
                    text: 'HOME',
                    width: 145.0,
                    height: 46.0,
                    fontSize: 16.0,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onHome != null) {
                        onHome!();
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
