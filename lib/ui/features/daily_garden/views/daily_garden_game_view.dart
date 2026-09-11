import 'package:flutter/material.dart';
import 'package:block_bloom/ui/features/game/views/game_view.dart';

/// Daily Garden Gameplay Screen (Screen 2 from design)
/// Wraps GameView with isDaily set to true to display Daily Garden top bar with leaf attachments
/// and DailyGardenGameOverView on game over.
class DailyGardenGameView extends StatelessWidget {
  const DailyGardenGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameView(
      levelNumber: 0,
      isDaily: true,
    );
  }
}
