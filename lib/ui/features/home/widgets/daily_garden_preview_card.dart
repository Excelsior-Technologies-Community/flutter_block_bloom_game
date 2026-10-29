import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_intro_view.dart';

/// Aesthetic Daily Garden Preview Card
///
/// Designed to sit directly below the CompactTop3LeaderboardCard on the Home View.
/// Features:
/// - Exact aesthetic symmetry with the leaderboard card (navy glassmorphism, gold border, back_design texture)
/// - Live mini-grid preview of today's unique board template silhouette with 3D gem accents
/// - Calendar date pill, challenge name, emoji, and tile count
/// - Dynamic attempt status badge ("1 ATTEMPT ONLY" / "COMPLETED ✓" with score)
/// - Flower bonus reward indicator (+50 🌸)
/// - Glossy emerald "PLAY NOW ›" CTA button with haptic feedback
class DailyGardenPreviewCard extends ConsumerWidget {
  final VoidCallback? onPressed;

  const DailyGardenPreviewCard({
    super.key,
    this.onPressed,
  });

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  void _handleTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    AudioService.instance.playClickSound();
    if (onPressed != null) {
      onPressed!();
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DailyGardenIntroView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateString = _getFormattedDate();
    final todayTemplate = BoardTemplate.getDailyTemplate(DateTime.now());

    final progressRepo = ref.watch(progressRepositoryProvider);
    final todayStr = progressRepo.getTodayDateString();
    final homeState = ref.watch(homeViewModelProvider);
    final progress = homeState.progress;

    final bool isCompletedToday =
        progress != null && progress.isDailyAttemptCompletedToday(todayStr);
    final int todayScore = progress?.dailyBestScore ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF001530).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFC800).withValues(alpha: 0.65),
              width: 1.2,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/leaderboard_icons/back_design.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              opacity: 0.08,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFFFC800).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left: Live Mini Board Preview
              _buildMiniBoardPreview(todayTemplate),

              const SizedBox(width: 10),

              // 2. Right: Challenge Info, Status Badge & CTA Button
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: "DAILY GARDEN" Title with Calendar Icon + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/daily_garden_calendar.png',
                              width: 13,
                              height: 13,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => SvgPicture.asset(
                                'assets/calendar_icon.svg',
                                width: 13,
                                height: 13,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dateString • DAILY GARDEN',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                          ],
                        ),

                        // Status badge (COMPLETED or 1 ATTEMPT)
                        _buildStatusBadge(isCompletedToday, todayScore),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Row 2: Template Name with Emoji & Tile Count Pill
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${todayTemplate.emoji} ${todayTemplate.name.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.chakraPetch(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002952),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF0052A4),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            '${todayTemplate.totalPlayableCells} TILES',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Row 3: Flower Reward Pill (Left) + Glossy CTA Button (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Flower reward badge
                        _buildFlowerBonusBadge(isCompletedToday),

                        // Action Play / View CTA Button
                        _buildGlossyActionButton(isCompletedToday),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Live Mini Board Silhouette Container
  Widget _buildMiniBoardPreview(BoardTemplate template) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF001024),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFFFFC800).withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Dynamic board shape drawn by custom painter
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: CustomPaint(
              size: const Size(54, 54),
              painter: _MiniBoardPreviewPainter(template: template),
            ),
          ),

          // 2. Specular glass reflection overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 26,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating mini corner emoji badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF001834).withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFC800).withValues(alpha: 0.5),
                  width: 0.6,
                ),
              ),
              child: Text(
                template.emoji,
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge indicating completion or attempt status
  Widget _buildStatusBadge(bool isCompleted, int score) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 9,
              color: Color(0xFF10B981),
            ),
            const SizedBox(width: 2.5),
            Text(
              score > 0 ? '$score PTS' : 'DONE',
              style: GoogleFonts.chakraPetch(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6EE7B7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC800).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Text(
        '1 ATTEMPT',
        style: GoogleFonts.chakraPetch(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFFFD54F),
        ),
      ),
    );
  }

  /// Flower reward badge preview
  Widget _buildFlowerBonusBadge(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF001E3D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.4),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/flower.png',
            width: 11,
            height: 11,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => const Icon(
              Icons.local_florist_rounded,
              size: 10,
              color: Color(0xFFFF80AB),
            ),
          ),
          const SizedBox(width: 3.5),
          Text(
            isCompleted ? 'REWARDED' : '+50 FLOWERS',
            style: GoogleFonts.chakraPetch(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD54F),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Glossy CTA button (PLAY NOW or VIEW RECAP)
  Widget _buildGlossyActionButton(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isCompleted
              ? const [Color(0xFF26A69A), Color(0xFF00796B)]
              : const [Color(0xFF34D399), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? const Color(0xFF80CBC4) : const Color(0xFFA7F3D0),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? const Color(0xFF00796B) : const Color(0xFF059669))
                .withValues(alpha: 0.45),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCompleted ? 'VIEW' : 'PLAY',
            style: GoogleFonts.chakraPetch(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 8,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Custom Painter that renders today's exact board template silhouette with 3D gems
class _MiniBoardPreviewPainter extends CustomPainter {
  final BoardTemplate template;

  const _MiniBoardPreviewPainter({required this.template});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = template.rows;
    final cols = template.cols;
    if (rows <= 0 || cols <= 0) return;

    const padding = 2.5;
    const gap = 1.4;
    final cellW = (size.width - (padding * 2) - ((cols - 1) * gap)) / cols;
    final cellH = (size.height - (padding * 2) - ((rows - 1) * gap)) / rows;
    final cellSize = math.min(cellW, cellH);

    final totalGridW = (cols * cellSize) + ((cols - 1) * gap);
    final totalGridH = (rows * cellSize) + ((rows - 1) * gap);
    final offsetX = (size.width - totalGridW) / 2;
    final offsetY = (size.height - totalGridH) / 2;

    final cellRadius = Radius.circular(cellSize > 5 ? 1.6 : 1.0);

    final emptyPaint = Paint()
      ..color = const Color(0xFF0C2442)
      ..style = PaintingStyle.fill;

    final emptyBorderPaint = Paint()
      ..color = const Color(0xFF1E4C80).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!template.isPlayable(r, c)) continue;

        final left = offsetX + (c * (cellSize + gap));
        final top = offsetY + (r * (cellSize + gap));
        final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, cellRadius);

        final cellKey = (r * 7 + c * 13) % 17;

        if (cellKey == 1 || cellKey == 5) {
          // Cyan Gem
          final gemPaint = Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
            ).createShader(rect);
          canvas.drawRRect(rrect, gemPaint);
          _drawCellSpecular(canvas, rect, cellRadius);
        } else if (cellKey == 2 || cellKey == 9) {
          // Emerald Green Gem
          final gemPaint = Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFAED581), Color(0xFF2E7D32)],
            ).createShader(rect);
          canvas.drawRRect(rrect, gemPaint);
          _drawCellSpecular(canvas, rect, cellRadius);
        } else if (cellKey == 3 || cellKey == 12) {
          // Amber / Gold Gem
          final gemPaint = Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE082), Color(0xFFE65100)],
            ).createShader(rect);
          canvas.drawRRect(rrect, gemPaint);
          _drawCellSpecular(canvas, rect, cellRadius);
        } else if (cellKey == 7) {
          // Rose Crystal
          final gemPaint = Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF48FB1), Color(0xFF880E4F)],
            ).createShader(rect);
          canvas.drawRRect(rrect, gemPaint);
          _drawCellSpecular(canvas, rect, cellRadius);
        } else {
          // Normal playable cell
          canvas.drawRRect(rrect, emptyPaint);
          canvas.drawRRect(rrect, emptyBorderPaint);
        }
      }
    }
  }

  void _drawCellSpecular(Canvas canvas, Rect rect, Radius radius) {
    final specRect = Rect.fromLTWH(
      rect.left + 0.4,
      rect.top + 0.4,
      rect.width - 0.8,
      rect.height * 0.42,
    );
    final specPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(specRect, Radius.circular(radius.x * 0.7)),
      specPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniBoardPreviewPainter oldDelegate) {
    return oldDelegate.template.id != template.id;
  }
}
