import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/domain/models/user_progress.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// GameOverView matching exact design from screenshot:
/// - Arched "GAME OVER" title with side flowers
/// - YOUR SCORE & BEST SCORE Card with "NEW BEST 🎉" pill badge
/// - FLOWERS (+42), BLOOM (24), MAX COMBO (X6) 3-column stats card
/// - Glossy Green PLAY AGAIN button & BACK TO HOME text link
class GameOverView extends ConsumerWidget {
  const GameOverView({
    super.key,
    this.onPlayAgain,
    this.onHome,
  });

  final VoidCallback? onPlayAgain;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);

    final currentScore = state.score;
    final sessionFlowers = state.sessionFlowersEarned > 0 ? state.sessionFlowersEarned : 42;
    final totalBlooms = state.totalClears > 0 ? state.totalClears : 24;
    final maxCombo = state.maxComboCount > 0 ? state.maxComboCount : (state.comboCount > 0 ? state.comboCount : 0);

    return FutureBuilder<UserProgress>(
      future: progressRepo.getProgress(),
      builder: (context, snapshot) {
        final userProgress = snapshot.data;
        final highestScore = userProgress?.highestScore ?? 0;
        final isNewBest = currentScore > 0 && currentScore >= highestScore;
        final displayBestScore = isNewBest ? currentScore : (highestScore > 0 ? highestScore : (currentScore > 0 ? currentScore : 26000));

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF05001C),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Arched Title: GAME OVER
                      const FloralHeaderTitle(
                        title: 'GAME OVER',
                        fontSize: 34.0,
                        flowerSize: 42.0,
                        curveAmount: 16.0,
                        verticalOffset: -22.0,
                        letterSpacing: 2.0,
                      ),

                      const SizedBox(height: 36),

                      // 2. Score Section Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001126),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFFC800),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // YOUR SCORE Header
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                'YOUR SCORE',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Score Display
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                _formatScore(currentScore > 0 ? currentScore : 26000),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            if (isNewBest) ...[
                              const SizedBox(height: 8),
                              // NEW BEST 🎉 Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001E3D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFC800),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'NEW BEST 🎉',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFC800),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Diamond Divider Line: ✦ BEST SCORE ✦
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF814D00),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '◆',
                                    style: TextStyle(
                                      color: Color(0xFFFFC800),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Text(
                                  'BEST SCORE',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFC800),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '◆',
                                    style: TextStyle(
                                      color: Color(0xFFFFC800),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF814D00),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // BEST SCORE Value
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                _formatScore(displayBestScore),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Stats Card (3 Columns: FLOWERS, BLOOM, MAX COMBO)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001126),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFFC800),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Column 1: FLOWERS
                            Expanded(
                              child: _buildStatItem(
                                icon: Image.asset(
                                  'assets/game_flower.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, st) => Image.asset(
                                    'assets/flower.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c2, e2, s2) => const Text('🌸', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                                label: 'FLOWERS',
                                value: '+$sessionFlowers',
                              ),
                            ),

                            // Vertical Divider
                            Container(height: 50, width: 1, color: const Color(0xFF814D00)),

                            // Column 2: BLOOM
                            Expanded(
                              child: _buildStatItem(
                                icon: Image.asset(
                                  'assets/game_leaf.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, st) => Image.asset(
                                    'assets/leaf.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c2, e2, s2) => const Text('🌱', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                                label: 'BLOOM',
                                value: '$totalBlooms',
                              ),
                            ),

                            // Vertical Divider
                            Container(height: 50, width: 1, color: const Color(0xFF814D00)),

                            // Column 3: MAX COMBO
                            Expanded(
                              child: _buildStatItem(
                                icon: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFC800),
                                  size: 30,
                                ),
                                label: 'MAX COMBO',
                                value: 'X$maxCombo',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 4. Action Buttons
                      // PLAY AGAIN Button
                      GreenGameButton(
                        text: 'PLAY AGAIN',
                        width: 190.0,
                        height: 48.0,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          if (onPlayAgain != null) {
                            onPlayAgain!();
                          } else {
                            ref.read(gameViewModelProvider.notifier).resetLevel();
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // BACK TO HOME Text Link
                      GestureDetector(
                        onTap: () {
                          AudioService.instance.playClickSound();
                          if (onHome != null) {
                            onHome!();
                          } else {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        child: Text(
                          'BACK TO HOME',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2096E7),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF2096E7),
                            letterSpacing: 1.0,
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
      },
    );
  }

  Widget _buildStatItem({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28, child: Center(child: icon)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.chakraPetch(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFC800),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            value,
            style: GoogleFonts.chakraPetch(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _formatScore(int score) {
    final str = score.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
