import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_over_view.dart';
import 'package:block_bloom/ui/providers.dart';

/// Daily Garden Intro Screen (Screen 1 from design)
/// Features night garden starry background, arched "DAILY GARDEN" title,
/// formatted date badge, golden "TODAY'S CHALLENGE" card with 8x8 preview board containing
/// 3D bevelled gem blocks, "ONE ATTEMPT ONLY" badge, and glossy green "PLAY TODAY" button.
class DailyGardenIntroView extends ConsumerWidget {
  const DailyGardenIntroView({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateString = _getFormattedDate();
    final progressRepo = ref.watch(progressRepositoryProvider);
    final todayStr = progressRepo.getTodayDateString();

    return FutureBuilder<UserProgress>(
      future: progressRepo.getProgress(),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final bool isCompletedToday = progress != null && progress.isDailyAttemptCompletedToday(todayStr);
        final int todayScore = progress?.dailyBestScore ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFF05001C),
          body: Stack(
            children: [
              // 1. Fullscreen Daily Garden Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/daily_garden_back.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF05001C),
                  ),
                ),
              ),

              // 2. Gradient Overlay to enhance UI element contrast over the background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.50),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Main Foreground Content
              SafeArea(
                child: Stack(
                  children: [
                    // Top Left Back Navigation Button
                    Positioned(
                      top: 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          AudioService.instance.playClickSound();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF001834).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFC800),
                              width: 1.4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFFFC800),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),

                              // Arched Title: DAILY GARDEN 3-portion layout with 2 flowers aligned & upward arch
                              const FloralHeaderTitle(
                                title: 'DAILY GARDEN',
                                fontSize: 34.0,
                                flowerSize: 42.0,
                                curveAmount: 16.0,
                                verticalOffset: -22.0,
                                letterSpacing: 2.0,
                              ),

                              const SizedBox(height: 8),

                              // Date Pill Badge: Calendar Icon 📅 + Date String (e.g. AUG 27)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/calendar_icon.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, st) => const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFFFFC800),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: Text(
                                      dateString,
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // 2. Main TODAY'S CHALLENGE Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001126).withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFFFC800),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x88000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // ✦ TODAY'S CHALLENGE ✦ Header line with golden flourishes
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              _buildHeaderFlourishIcon(),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Container(
                                                  height: 1.2,
                                                  color: const Color(0xFF814D00),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            "TODAY'S CHALLENGE",
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFFFC800),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 1.2,
                                                  color: const Color(0xFF814D00),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              _buildHeaderFlourishIcon(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      isCompletedToday
                                          ? 'Challenge completed for today!'
                                          : '1.5x Score Boost Challenge!',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isCompletedToday ? const Color(0xFF6EE7B7) : const Color(0xFFB0C4DE),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // 8x8 Grid Preview Board
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF001834),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF003366),
                                          width: 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x66000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: GridView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 8,
                                            mainAxisSpacing: 3,
                                            crossAxisSpacing: 3,
                                          ),
                                          itemCount: 64,
                                          itemBuilder: (context, index) {
                                            final row = index ~/ 8;
                                            final col = index % 8;
                                            return _buildPresetGridCell(row, col);
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Bottom Attempt Status Pill Box
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00162E),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isCompletedToday ? const Color(0xFF10B981) : const Color(0xFFFFC800),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              isCompletedToday
                                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                                                  : Image.asset(
                                                      'assets/garden_leaf.png',
                                                      width: 18,
                                                      height: 18,
                                                      errorBuilder: (ctx, err, st) => Image.asset(
                                                        'assets/leaf.png',
                                                        width: 18,
                                                        height: 18,
                                                        errorBuilder: (c2, e2, s2) => const Text('🍃', style: TextStyle(fontSize: 14)),
                                                      ),
                                                    ),
                                              const SizedBox(width: 6),
                                              ShaderMask(
                                                shaderCallback: (bounds) => LinearGradient(
                                                  colors: isCompletedToday
                                                      ? [const Color(0xFF6EE7B7), const Color(0xFF10B981)]
                                                      : [
                                                          const Color(0xFFD2FF5D),
                                                          const Color(0xFF90CC37),
                                                          const Color(0xFF5CA519),
                                                          const Color(0xFF3C8C07),
                                                          const Color(0xFF308300),
                                                        ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ).createShader(bounds),
                                                child: Text(
                                                  isCompletedToday ? 'ATTEMPT COMPLETED TODAY' : 'ONE ATTEMPT ONLY (1.5x BOOST)',
                                                  style: GoogleFonts.chakraPetch(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: -0.16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isCompletedToday
                                                ? 'Today\'s Score: $todayScore • Come back tomorrow!'
                                                : 'Beat your best score today! 1 attempt available.',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isCompletedToday ? const Color(0xFF6EE7B7) : const Color(0xFFFFE699),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // 3. Main Action Button with garden_leaf.png
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  GreenGameButton(
                                    text: isCompletedToday ? 'VIEW RESULT' : 'PLAY TODAY',
                                    width: 210.0,
                                    height: 48.0,
                                    onPressed: () async {
                                      AudioService.instance.playClickSound();
                                      if (isCompletedToday) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const DailyGardenGameOverView(),
                                          ),
                                        );
                                      } else {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const DailyGardenGameView(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  Positioned(
                                    right: -8,
                                    bottom: 2,
                                    child: Image.asset(
                                      'assets/garden_leaf.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) => Image.asset(
                                        'assets/garden_leaf2.png',
                                        width: 26,
                                        height: 26,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c2, e2, s2) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderFlourishIcon() {
    return Image.asset(
      'assets/score.png',
      width: 16,
      height: 16,
      errorBuilder: (ctx, err, st) => const Icon(
        Icons.auto_awesome,
        color: Color(0xFFFFC800),
        size: 12,
      ),
    );
  }

  /// 8x8 Grid Cell builder with 3D gem block styling matching design screenshot 1
  Widget _buildPresetGridCell(int row, int col) {
    // 1. Cyan / Ice-Blue 2x2 at top left (rows 0..1, cols 0..1)
    if ((row == 0 || row == 1) && (col == 0 || col == 1)) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFF81D4FA), Color(0xFF29B6F6), Color(0xFF0288D1)],
        borderColor: const Color(0xFFB3E5FC),
        icon: Icons.grid_view_rounded,
        iconColor: const Color(0x66FFFFFF),
      );
    }
    // 2. Turquoise / Teal Star 1x2 (rows 0..1, col 2)
    if ((row == 0 || row == 1) && col == 2) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFF80CBC4), Color(0xFF26A69A), Color(0xFF004D40)],
        borderColor: const Color(0xFFE0F2F1),
        icon: Icons.auto_awesome,
        iconColor: const Color(0x88FFFFFF),
      );
    }
    // 3. Bright Green Leaf/Gem 1x3 at top right (rows 0..2, col 7)
    if ((row == 0 || row == 1 || row == 2) && col == 7) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFAED581), Color(0xFF66BB6A), Color(0xFF2E7D32)],
        borderColor: const Color(0xFFDCEDC8),
        icon: Icons.eco_rounded,
        iconColor: const Color(0x77FFFFFF),
      );
    }
    // 4. Red Cracked Crystal 2x2 at middle right (rows 2..3, cols 5..6)
    if ((row == 2 || row == 3) && (col == 5 || col == 6)) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFFF8A65), Color(0xFFEF5350), Color(0xFFB71C1C)],
        borderColor: const Color(0xFFFFCCBC),
        icon: Icons.grain_rounded,
        iconColor: const Color(0x77FFFFFF),
      );
    }
    // 5. Pink Light Reflection Gem 1x2 at bottom right (row 6, cols 6..7)
    if (row == 6 && (col == 6 || col == 7)) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFF48FB1), Color(0xFFEC407A), Color(0xFF880E4F)],
        borderColor: const Color(0xFFFCE4EC),
        icon: Icons.wb_twilight_rounded,
        iconColor: const Color(0x88FFFFFF),
      );
    }

    // Empty dark navy grid cell
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000F24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF001A38),
          width: 0.8,
        ),
      ),
    );
  }

  /// Custom 3D Gem Block builder with bevel border, gradient depth & texture icon
  Widget _build3DGemBlock({
    required List<Color> gradientColors,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.6),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy Top Highlight Sweep
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Inner Motif Icon
          Center(
            child: Icon(
              icon,
              size: 14,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

