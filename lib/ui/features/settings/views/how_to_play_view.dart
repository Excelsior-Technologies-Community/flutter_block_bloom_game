import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';

class HowToPlayView extends StatelessWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = math.min(size.width * 0.90, 420);

    return Scaffold(
      backgroundColor: const Color(0xFF001026),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Night Garden Background
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF001026),
              ),
            ),
          ),

          // 2. Ambient Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Screen Content Structure
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Navigation Bar (Circular Gold Back Button)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              AudioService.instance.playClickSound();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF001834),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFC800),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFFFFC800),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Floral Arched Title
                      const FloralHeaderTitle(
                        title: 'HOW TO PLAY',
                        fontSize: 26.0,
                        flowerSize: 34.0,
                        curveAmount: 12.0,
                        verticalOffset: -16.0,
                        letterSpacing: 1.5,
                      ),

                      const SizedBox(height: 10),

                      // Guide Subtitle Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001834).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFC800).withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: Color(0xFFFFC800),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'GAMEPLAY GUIDE & FLORAL POWERS',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.90),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Central Guide Container
                      Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFF001834),
                          borderRadius: BorderRadius.circular(18),
                          image: const DecorationImage(
                            image: AssetImage('assets/leaderboard_icons/back_design.png'),
                            fit: BoxFit.none,
                            repeat: ImageRepeat.repeat,
                            alignment: Alignment.center,
                            scale: 2.8,
                            colorFilter: ColorFilter.mode(
                              Color(0xFF001834),
                              BlendMode.modulate,
                            ),
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFC800),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFC800).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Intro Game Objective Banner
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF065F46).withValues(alpha: 0.5),
                                      const Color(0xFF001834).withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🧩', style: TextStyle(fontSize: 26)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'THE OBJECTIVE',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFC800),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Drag vibrant blocks onto the board, clear full lines, bloom botanical powers, and grow your floral dream garden!',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.90),
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Fashionable 3-Card Highlights Row (Single Balanced Line)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '🧩',
                                      title: 'DRAG & DROP',
                                      subtitle: '8x8 Grid',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '💥',
                                      title: 'BLAST LINES',
                                      subtitle: 'Rows & Cols',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '🌸',
                                      title: 'GROW FLORA',
                                      subtitle: 'Garden Powers',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Step 1: Placing Blocks
                              _buildStepSection(
                                number: '01',
                                icon: Icons.grid_view_rounded,
                                title: 'DRAG & PLACE BLOCKS',
                                content:
                                    'Pieces arrive in sets of 3 at the bottom tray. Drag any piece onto the 8x8 grid into empty slots. Note: Pieces cannot be rotated, so plan your spaces carefully!',
                              ),

                              _buildDivider(),

                              // Step 2: Clearing Lines
                              _buildStepSection(
                                number: '02',
                                icon: Icons.auto_awesome_rounded,
                                title: 'CLEAR ROWS & COLUMNS',
                                content:
                                    'Fill an entire horizontal row or vertical column to blast the blocks away and earn points. Clearing multiple rows or columns in a single turn triggers a Multi-Clear bonus!',
                              ),

                              _buildDivider(),

                              // Step 3: Combos & Streaks
                              _buildStepSection(
                                number: '03',
                                icon: Icons.local_fire_department_rounded,
                                title: 'CHAIN COMBOS & MULTIPLIERS',
                                content:
                                    'Clear lines with consecutive moves to build up your Combo Streak! Combos supercharge your score with multipliers from 2.4x up to a massive 5.0x!',
                              ),

                              _buildDivider(),

                              // Step 4: Flower Powers & Boosts
                              _buildStepSection(
                                number: '04',
                                icon: Icons.local_florist_rounded,
                                title: 'BLOOM SPECIAL POWERS',
                                content:
                                    'As you play and clear blocks, you fill flower power pools that grant game-changing abilities:',
                                customChild: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    _buildPowerChip(
                                      emoji: '🌻',
                                      name: 'SUNFLOWER BOOST (3 FLOWERS)',
                                      description:
                                          'Activates an instant 2x Score Multiplier on your next line blast!',
                                      accentColor: const Color(0xFFFFC800),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPowerChip(
                                      emoji: '💧',
                                      name: 'BLUE REFRESH (3 FLOWERS)',
                                      description:
                                          'Grants a Tray Refresh charge to swap your 3 pieces when stuck!',
                                      accentColor: const Color(0xFF60A5FA),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPowerChip(
                                      emoji: '💣',
                                      name: 'RED BLOOM BOMB (5 FLOWERS)',
                                      description:
                                          'Spawns a powerful 1x1 Bloom Bomb piece in your tray that detonates adjacent blocks in a 3x3 blast radius!',
                                      accentColor: const Color(0xFFF87171),
                                    ),
                                  ],
                                ),
                              ),

                              _buildDivider(),

                              // Step 5: Garden Decorating
                              _buildStepSection(
                                number: '05',
                                icon: Icons.park_rounded,
                                title: 'EXPAND YOUR GARDEN',
                                content:
                                    'Every cleared line and finished level awards flowers and petals. Visit the Garden from the Home screen to unlock fresh flower beds, plant rare blooms, and build your peaceful sanctuary.',
                              ),

                              _buildDivider(),

                              // Step 6: Daily Garden Challenge
                              _buildStepSection(
                                number: '06',
                                icon: Icons.calendar_month_rounded,
                                title: 'DAILY GARDEN CHALLENGE',
                                content:
                                    'Play a unique daily puzzle every day! Maintain your calendar streak, earn special monthly awards, and enjoy a permanent 1.5x score bonus during daily runs.',
                              ),

                              _buildDivider(),

                              // Step 7: Game Over & Continuation
                              _buildStepSection(
                                number: '07',
                                icon: Icons.replay_circle_filled_rounded,
                                title: 'GAME OVER & SECOND CHANCE',
                                content:
                                    'The round ends when none of the pieces in your tray fit on the board. You receive 1 second-chance continuation per game to clear crowded spaces and push your high score further!',
                              ),

                              const SizedBox(height: 24),

                              // Bottom Play Action Button
                              Center(
                                child: GlossyGameButton.green(
                                  text: "LET'S PLAY!",
                                  height: 48,
                                  width: 190,
                                  fontSize: 16.5,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    AudioService.instance.playClickSound();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Game Motto Footer
                              Center(
                                child: Text(
                                  'Bloom your garden, one block at a time. 🌸',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3-Card Feature Micro-Card
  static Widget _buildHighlightCard({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF001026).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFFFFC800).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC800).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFC800).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFE082),
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.80),
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Individual Step Section
  static Widget _buildStepSection({
    required String number,
    required IconData icon,
    required String title,
    required String content,
    Widget? customChild,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gold Number Tag
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC800),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.45),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  number,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001834),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Icon(
                icon,
                size: 18,
                color: const Color(0xFFFFC800),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.55,
                    letterSpacing: 0.2,
                  ),
                ),
                ?customChild,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Visual Power Pill for Flower Powers
  static Widget _buildPowerChip({
    required String emoji,
    required String name,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF001026).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Subtle separator between steps
  static Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFFC800).withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
