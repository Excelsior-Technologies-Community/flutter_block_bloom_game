import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_over_view.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/ui/features/game/widgets/contoured_board_frame.dart';

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
    final todayTemplate = BoardTemplate.getDailyTemplate(DateTime.now());

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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/daily_garden_calendar.png',
                                    width: 19,
                                    height: 19,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (ctx, err, st) => SvgPicture.asset(
                                      'assets/calendar_icon.svg',
                                      width: 19,
                                      height: 19,
                                      fit: BoxFit.contain,
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

                              // 2. Main TODAY'S CHALLENGE Card with back_design.png
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001834),
                                  borderRadius: BorderRadius.circular(22),
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
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x88000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                    child: Column(
                                      children: [
                                        // TODAY'S CHALLENGE line using daily_garden_line.png
                                        Image.asset(
                                          'assets/daily_garden_line.png',
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          isCompletedToday
                                              ? 'Challenge completed for today!'
                                              : 'A new puzzle every day!',
                                          style: GoogleFonts.chakraPetch(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isCompletedToday ? const Color(0xFF6EE7B7) : const Color(0xFFB0C4DE),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Today's Arena Template Badge
                                        Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00142A).withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFFC800),
                                              width: 1.2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x66000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(todayTemplate.emoji, style: const TextStyle(fontSize: 16)),
                                              const SizedBox(width: 7),
                                              Text(
                                                todayTemplate.name.toUpperCase(),
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFFFFD54F),
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF003366),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  '${todayTemplate.totalPlayableCells} TILES',
                                                  style: GoogleFonts.chakraPetch(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF6EE7B7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // Contoured Preview Board hugging today's template silhouette
                                        AspectRatio(
                                          aspectRatio: 1.0,
                                          child: ContouredBoardFrame(
                                            template: todayTemplate,
                                            gridSize: todayTemplate.rows,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF003675),
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                                padding: const EdgeInsets.all(2.5),
                                                child: GridView.builder(
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: todayTemplate.rows,
                                                    mainAxisSpacing: 3,
                                                    crossAxisSpacing: 3,
                                                  ),
                                                  itemCount: todayTemplate.rows * todayTemplate.cols,
                                                  itemBuilder: (context, index) {
                                                    final row = index ~/ todayTemplate.cols;
                                                    final col = index % todayTemplate.cols;
                                                    if (!todayTemplate.isPlayable(row, col)) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return _buildDailyPreviewGridCell(todayTemplate, row, col);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        // Bottom Attempt Status Pill Box
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00142A).withValues(alpha: 0.85),
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
                                                          fit: BoxFit.contain,
                                                          filterQuality: FilterQuality.high,
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
                                                      isCompletedToday ? 'ATTEMPT COMPLETED TODAY' : 'ONE ATTEMPT ONLY',
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
                                              const SizedBox(height: 3),
                                              Text(
                                                isCompletedToday
                                                    ? 'Today\'s Score: $todayScore • Come back tomorrow!'
                                                    : 'Beat your best score today!',
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isCompletedToday ? const Color(0xFF6EE7B7) : const Color(0xFFB0C4DE),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  /// Dynamic Grid Cell builder for Today's Template with glowing 3D gems
  Widget _buildDailyPreviewGridCell(BoardTemplate template, int row, int col) {
    final cellKey = (row * 7 + col * 13) % 17;

    // 1. Cyan / Ice-Blue Gem
    if (cellKey == 1 || cellKey == 5) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFF81D4FA), Color(0xFF29B6F6), Color(0xFF0288D1)],
        borderColor: const Color(0xFFB3E5FC),
        icon: Icons.grid_view_rounded,
        iconColor: const Color(0x66FFFFFF),
      );
    }
    // 2. Emerald Green Sprout
    if (cellKey == 2 || cellKey == 9) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFAED581), Color(0xFF66BB6A), Color(0xFF2E7D32)],
        borderColor: const Color(0xFFDCEDC8),
        icon: Icons.eco_rounded,
        iconColor: const Color(0x77FFFFFF),
      );
    }
    // 3. Amber / Sunflower Gem
    if (cellKey == 3 || cellKey == 12) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFE65100)],
        borderColor: const Color(0xFFFFF8E1),
        icon: Icons.wb_sunny_rounded,
        iconColor: const Color(0x88FFFFFF),
      );
    }
    // 4. Pink Rose Crystal
    if (cellKey == 7) {
      return _build3DGemBlock(
        gradientColors: const [Color(0xFFF48FB1), Color(0xFFEC407A), Color(0xFF880E4F)],
        borderColor: const Color(0xFFFCE4EC),
        icon: Icons.auto_awesome,
        iconColor: const Color(0x88FFFFFF),
      );
    }

    // Playable empty grid cell
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001F47),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF004080).withValues(alpha: 0.6),
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

