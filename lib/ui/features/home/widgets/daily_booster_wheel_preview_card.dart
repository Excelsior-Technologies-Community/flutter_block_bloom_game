import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/features/shop/widgets/daily_booster_wheel_dialog.dart';
import 'package:block_bloom/ui/providers.dart';

class DailyBoosterWheelPreviewCard extends ConsumerStatefulWidget {
  const DailyBoosterWheelPreviewCard({super.key});

  @override
  ConsumerState<DailyBoosterWheelPreviewCard> createState() =>
      _DailyBoosterWheelPreviewCardState();
}

class _DailyBoosterWheelPreviewCardState
    extends ConsumerState<DailyBoosterWheelPreviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatCooldown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(progressRepositoryProvider);
    final bool isFree = repo.isBoosterWheelFreeSpinAvailable();
    final int tokens = repo.getBoosterWheelTokens();
    final Duration cooldown = repo.getBoosterWheelRemainingCooldown();
    final bool canSpin = isFree || tokens > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          AudioService.instance.playClickSound();
          HapticFeedback.lightImpact();
          await showDailyBoosterWheel(context);
          if (mounted) {
            ref.read(homeViewModelProvider.notifier).loadProgress();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF001530).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canSpin
                  ? const Color(0xFFFFC800).withValues(alpha: 0.85)
                  : const Color(0xFF475569).withValues(alpha: 0.6),
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
              if (canSpin)
                BoxShadow(
                  color: const Color(0xFFFFC800).withValues(alpha: 0.20),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            children: [
              // 3D Mini Token Icon
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(34, 34),
                      painter: SpinTokenIconPainter(),
                    ),
                    if (canSpin)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Title & Status with Chakra Petch font
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'BOOSTER WHEEL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.chakraPetch(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (canSpin) ...[
                          const SizedBox(width: 5),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.65 + (_pulseController.value * 0.35),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'READY!',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canSpin
                          ? 'Spin to win flowers, boosters & gems!'
                          : 'Next free token in ${_formatCooldown(cooldown)}',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 11,
                        color: canSpin
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3D Emerald "SPIN" CTA Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canSpin
                        ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                        : [const Color(0xFF334155), const Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canSpin
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF64748B),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (canSpin)
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      canSpin ? 'SPIN' : 'VIEW',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white,
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
}
