import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/booster_reward.dart';
import 'package:block_bloom/ui/providers.dart';

/// Opens the Block Bloom High-End Arcade Daily Booster Wheel Dialog
Future<void> showDailyBoosterWheel(BuildContext context) {
  HapticFeedback.heavyImpact();
  AudioService.instance.playClickSound();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DailyBoosterWheel',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 480),
    pageBuilder: (ctx, anim1, anim2) {
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Material(
              color: Colors.transparent,
              child: const DailyBoosterWheelDialog(),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 7.0 * animation.value,
          sigmaY: 7.0 * animation.value,
        ),
        child: FadeTransition(
          opacity: animation,
          child: Transform.scale(
            scale: curved.value.clamp(0.01, 1.0),
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

class DailyBoosterWheelDialog extends ConsumerStatefulWidget {
  const DailyBoosterWheelDialog({super.key});

  @override
  ConsumerState<DailyBoosterWheelDialog> createState() =>
      _DailyBoosterWheelDialogState();
}

class _DailyBoosterWheelDialogState extends ConsumerState<DailyBoosterWheelDialog>
    with TickerProviderStateMixin {
  // 1. Wheel spin physics animation
  late final AnimationController _spinController;
  late Animation<double> _spinAnimation;

  // 2. Continuous rotating God-Rays halo
  late final AnimationController _rayController;

  // 3. Shimmer & light sheen sweep controller
  late final AnimationController _shimmerController;

  // 4. Marquee LED light bulbs chaser controller
  late final AnimationController _chaserController;

  // 5. Confetti celebration controller
  late final ConfettiController _confettiController;

  // 6. Spring pointer deflection
  double _pointerAngle = 0.0;
  double _lastTickSlice = 0.0;

  // 7. Blocked shake feedback controller
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Real-time countdown timer ticker
  Timer? _countdownTicker;
  Duration _remainingCooldown = Duration.zero;
  bool _isFreeAvailable = true;
  int _spinTokens = 0;

  bool _isSpinning = false;
  int _targetIndex = 0;
  double _currentWheelAngle = 0.0;

  static const int kExtraSpinGemCost = 20;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _chaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _refreshTimerState();
    _startCountdownTicker();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _spinController.dispose();
    _rayController.dispose();
    _shimmerController.dispose();
    _chaserController.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdownTicker() {
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _refreshTimerState();
      }
    });
  }

  void _refreshTimerState() {
    final repo = ref.read(progressRepositoryProvider);
    final free = repo.isBoosterWheelFreeSpinAvailable();
    final tokens = repo.getBoosterWheelTokens();
    final cooldown = repo.getBoosterWheelRemainingCooldown();

    setState(() {
      _isFreeAvailable = free;
      _spinTokens = tokens;
      _remainingCooldown = cooldown;
    });
  }

  bool get _canSpinFreeOrToken => !_isSpinning && (_isFreeAvailable || _spinTokens > 0);

  // Computes which slice is currently under the top 12 o'clock pointer
  int get _currentActiveSliceIndex {
    const sliceAngle = 2 * math.pi / 8;
    // Normalized angle in [0, 2pi)
    final normalized = (2 * math.pi - (_currentWheelAngle % (2 * math.pi)) + (sliceAngle / 2)) % (2 * math.pi);
    final idx = (normalized / sliceAngle).floor() % 8;
    return idx.clamp(0, 7);
  }

  void _startSpinSequence({required bool isPaidGemSpin}) async {
    if (_isSpinning) return;

    if (isPaidGemSpin) {
      final repo = ref.read(progressRepositoryProvider);
      final progress = await repo.getProgress();
      if (!mounted) return;

      if (progress.gems < kExtraSpinGemCost) {
        _shakeController.forward(from: 0.0);
        AudioService.instance.playClickSound();
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need $kExtraSpinGemCost Gems! You have ${progress.gems} 💎.',
                    style: GoogleFonts.sniglet(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFC2185B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Deduct gems for paid spin
      await repo.addGems(-kExtraSpinGemCost);
    }

    // Weighted Probability: Jackpot is exciting & rare, others nicely balanced
    final rand = math.Random();
    final roll = rand.nextDouble();
    if (roll < 0.08) {
      _targetIndex = 0; // 👑 JACKPOT 500 FLOWERS!
    } else if (roll < 0.22) {
      _targetIndex = 7; // 250 Flowers
    } else if (roll < 0.36) {
      _targetIndex = 5; // 100 Flowers
    } else if (roll < 0.50) {
      _targetIndex = 2; // Tray Refresh
    } else if (roll < 0.64) {
      _targetIndex = 1; // 2X Score Multiplier
    } else if (roll < 0.78) {
      _targetIndex = 3; // Bloom Bomb
    } else if (roll < 0.90) {
      _targetIndex = 4; // Bloom Hammer
    } else {
      _targetIndex = 6; // 25 Gems
    }

    final targetReward = kDailyBoosterRewards[_targetIndex];

    const numSlices = 8;
    const sliceAngle = 2 * math.pi / numSlices;
    final targetWedgeCenter = _targetIndex * sliceAngle;
    final landingAngle = (2 * math.pi - targetWedgeCenter) % (2 * math.pi);

    // 7 Grand rotations + landing alignment
    const fullSpins = 7;
    final startAngle = _currentWheelAngle % (2 * math.pi);
    final endAngle = startAngle + (fullSpins * 2 * math.pi) + landingAngle;

    _spinAnimation = Tween<double>(begin: startAngle, end: endAngle).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: Curves.fastEaseInToSlowEaseOut,
      ),
    );

    setState(() {
      _isSpinning = true;
    });

    AudioService.instance.playClickSound();

    _spinController.reset();
    _spinController.addListener(_onSpinTick);
    _spinController.forward().then((_) {
      if (!mounted) return;
      _spinController.removeListener(_onSpinTick);
      _currentWheelAngle = endAngle;
      setState(() {
        _isSpinning = false;
        _pointerAngle = 0.0;
      });

      _onSpinComplete(targetReward, wasPaidGemSpin: isPaidGemSpin);
    });
  }

  void _onSpinTick() {
    if (!mounted) return;
    final currentAngle = _spinAnimation.value;
    setState(() {
      _currentWheelAngle = currentAngle;
    });

    // Pointer deflection calculation
    const sliceAngle = 2 * math.pi / 8;
    final currentSlice = (currentAngle / sliceAngle);
    final delta = (currentSlice - _lastTickSlice).abs();

    if (delta >= 1.0) {
      _lastTickSlice = currentSlice.floorToDouble();

      AudioService.instance.playClickSound();

      setState(() {
        _pointerAngle = -0.34;
      });
      Future.delayed(const Duration(milliseconds: 40), () {
        if (mounted) {
          setState(() {
            _pointerAngle = 0.0;
          });
        }
      });
    }
  }

  void _onSpinComplete(BoosterReward reward, {required bool wasPaidGemSpin}) {
    AudioService.instance.playClearSound();
    HapticFeedback.heavyImpact();

    // Trigger dual-cannon celebration confetti!
    _confettiController.play();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return GrandBoosterRewardClaimDialog(
          reward: reward,
          onClaim: () async {
            final repo = ref.read(progressRepositoryProvider);
            if (!wasPaidGemSpin) {
              await repo.recordBoosterWheelSpinRedeemed(reward);
            } else {
              // Directly credit won reward without touching free 24h timer
              switch (reward.type) {
                case BoosterRewardType.flowers:
                  await repo.addFlowers(reward.amount);
                  break;
                case BoosterRewardType.gems:
                  await repo.addGems(reward.amount);
                  break;
                case BoosterRewardType.trayRefresh:
                  await repo.addBooster('refresh', reward.amount);
                  break;
                case BoosterRewardType.bloomBomb:
                  await repo.addBooster('bomb', reward.amount);
                  break;
                case BoosterRewardType.scoreMultiplier:
                  await repo.addBooster('double_score', reward.amount);
                  break;
                case BoosterRewardType.bloomHammer:
                  await repo.addBooster('hammer', reward.amount);
                  break;
                case BoosterRewardType.spinToken:
                  await repo.addBoosterWheelTokens(reward.amount);
                  break;
              }
            }

            if (dialogCtx.mounted) {
              Navigator.of(dialogCtx).pop();
            }
            if (mounted) {
              _refreshTimerState();
            }
          },
        );
      },
    );
  }

  void _showInfoDialog() {
    AudioService.instance.playClickSound();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF0F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF4081), width: 3),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4081), Color(0xFFD81B60)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Booster Wheel',
              style: GoogleFonts.cherryCreamSoda(
                fontSize: 22,
                color: const Color(0xFFC2185B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('👑', 'Jackpot 500 🌸', 'Massive floral reward to accelerate garden upgrades!'),
            const SizedBox(height: 10),
            _buildInfoRow('🌻', '2X Multiplier', 'Doubles score on all line clears in your next match.'),
            const SizedBox(height: 10),
            _buildInfoRow('🔄', 'Tray Refresh x2', 'Swap stuck pieces for 3 fresh ones in-game.'),
            const SizedBox(height: 10),
            _buildInfoRow('💣', 'Bloom Bomb', 'Clears a 3x3 flower blast on the grid.'),
            const SizedBox(height: 10),
            _buildInfoRow('🔨', 'Bloom Hammer', 'Smashes any stubborn single block.'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '• Free spin resets automatically every 24 hours.\n• Extra spins can be unlocked anytime using Gems or Tokens!',
                style: GoogleFonts.sniglet(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF880E4F),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'GOT IT!',
              style: GoogleFonts.sniglet(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF4081),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.sniglet(fontSize: 13, color: const Color(0xFF374151)),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2185B)),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCooldown(Duration d) {
    if (d.inSeconds <= 0) return 'FREE SPIN READY!';
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
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = math.min(screenSize.width * 0.92, 360.0);
    final activeReward = kDailyBoosterRewards[_currentActiveSliceIndex];

    return PopScope(
      canPop: !_isSpinning,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // -------------------------------------------------------------
          // ROTATING GOLDEN GOD-RAYS HALO
          // -------------------------------------------------------------
          Positioned(
            top: -40,
            child: AnimatedBuilder(
              animation: _rayController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rayController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(420, 420),
                painter: GodRaysPainter(
                  rayCount: 16,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.22),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------
          // MAIN HANGING SIGNBOARD DIALOG (Candy Cane Frame & Soft Frosted Body)
          // -------------------------------------------------------------
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hanging String from the top ceiling
                  CustomPaint(
                    size: const Size(22, 26),
                    painter: HangingStringPainter(),
                  ),

                  // Hanging Card Frame with Eyelet Arch
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Main Card Container with 3D Diagonal Candy Cane Border
                      Container(
                        width: dialogWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6F7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.40),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: CandyCaneBorderPainter(
                            borderWidth: 8.5,
                            borderRadius: 30.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Header Row: Info (Left), "Booster Wheel" Title, Close (Right)
                                _buildHeaderRow(),

                                const SizedBox(height: 8),

                                // Live Pointer Prize HUD Pill
                                _buildLivePrizeHud(activeReward),

                                const SizedBox(height: 8),

                                // Central 3D Arcade Spinner Wheel
                                _buildWheelSection(dialogWidth),

                                const SizedBox(height: 10),

                                // 3D Blue Pedestal Stand with Spin CTA & Gem Option
                                _buildPedestalStand(dialogWidth),

                                const SizedBox(height: 12),

                                // Dotted Divider Line
                                CustomPaint(
                                  size: Size(dialogWidth - 40, 2),
                                  painter: DottedLinePainter(
                                    color: const Color(0xFFFFB4C4),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Real-Time Countdown Timer Section
                                _buildTimerSection(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Hanging Eyelet Grommet Ring at Top
                      Positioned(
                        top: -9,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF80AB), Color(0xFFD81B60)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF6F7),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Bottom Event Info Pill
                  _buildBottomEventPill(dialogWidth),
                ],
              ),
            ),
          )
              .animate()
              .scale(
                duration: 480.ms,
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms),

          // -------------------------------------------------------------
          // FULLSCREEN CONFETTI CANNON CELEBRATION BURST
          // -------------------------------------------------------------
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 35,
              gravity: 0.18,
              colors: const [
                Color(0xFFFF4081),
                Color(0xFFFFD54F),
                Color(0xFF38BDF8),
                Color(0xFF10B981),
                Color(0xFFA855F7),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SUBSECTION BUILDERS
  // =========================================================================

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Glossy Pink Info (i) Button
        GestureDetector(
          onTap: _showInfoDialog,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFFD81B60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF880E4F).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),

        // Center: "Booster Wheel" Title in Cursive Bubble Typography
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                children: [
                  // Outer Stroke
                  Text(
                    'Booster Wheel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cherryCreamSoda(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 5.0
                        ..color = const Color(0xFFD81B60),
                    ),
                  ),
                  // Crisp White Face
                  Text(
                    'Booster Wheel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cherryCreamSoda(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF880E4F),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right: Glossy Pink Close (X) Button
        GestureDetector(
          onTap: () {
            if (_isSpinning) return;
            AudioService.instance.playClickSound();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  /// Live HUD Pill showing current prize under the pointer
  Widget _buildLivePrizeHud(BoosterReward active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            active.baseColor.withValues(alpha: 0.9),
            active.accentColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: active.baseColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(active.iconEmoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            active.title,
            style: GoogleFonts.sniglet(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSection(double dialogWidth) {
    final wheelSize = math.min(dialogWidth - 44, 256.0);

    return SizedBox(
      width: wheelSize,
      height: wheelSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Rotating Wheel Canvas with Non-Collapsing Clean Badges
          Transform.rotate(
            angle: _currentWheelAngle,
            child: CustomPaint(
              size: Size(wheelSize, wheelSize),
              painter: CandyCarnivalWheelPainter(
                rewards: kDailyBoosterRewards,
              ),
            ),
          ),

          // 2. Outer 24K Gold Rim with Animated Marquee Chaser LED Lights
          AnimatedBuilder(
            animation: _chaserController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(wheelSize, wheelSize),
                painter: MarqueeChaserRimPainter(
                  chaserProgress: _isSpinning
                      ? (_chaserController.value * 4) % 1.0
                      : _chaserController.value,
                  isSpinning: _isSpinning,
                ),
              );
            },
          ),

          // 3. Central Grand Starburst Hub
          CustomPaint(
            size: Size(wheelSize * 0.32, wheelSize * 0.32),
            painter: CandyWheelHubPainter(),
          ),

          // 4. Top Sculpted Pointer Arrow (at 12 o'clock)
          Positioned(
            top: -12,
            child: Transform.rotate(
              angle: _pointerAngle,
              alignment: Alignment.topCenter,
              child: CustomPaint(
                size: const Size(26, 38),
                painter: SculptedPointerPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedestalStand(double dialogWidth) {
    final pedestalWidth = math.min(dialogWidth - 50, 220.0);
    final canSpin = _canSpinFreeOrToken;

    return SizedBox(
      width: pedestalWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Candy-Blue Pedestal Stand
          GestureDetector(
            onTap: () => _startSpinSequence(isPaidGemSpin: false),
            child: SizedBox(
              width: pedestalWidth,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Blue trapezoid base with glossy top curve
                  CustomPaint(
                    size: Size(pedestalWidth, 52),
                    painter: BluePedestalPainter(
                      isGlowing: canSpin,
                    ),
                  ),

                  // Content inside Pedestal slot
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (canSpin) ...[
                            Text(
                              _isSpinning
                                  ? 'SPINNING...'
                                  : (_isFreeAvailable ? 'FREE SPIN' : 'SPIN (1 TOKEN)'),
                              style: GoogleFonts.sniglet(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF0369A1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomPaint(
                              size: const Size(26, 26),
                              painter: SpinTokenIconPainter(),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFB0BEC5),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '0',
                              style: GoogleFonts.sniglet(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.9),
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF0284C7),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            CustomPaint(
                              size: const Size(24, 24),
                              painter: SpinTokenIconPainter(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Extra Spin with Gems Button (Available when in daily cooldown)
          if (!canSpin) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _startSpinSequence(isPaidGemSpin: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'EXTRA SPIN (20 GEMS)',
                      style: GoogleFonts.sniglet(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    final isReady = _isFreeAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(24, 26),
                painter: StopwatchIconPainter(),
              ),
              const SizedBox(width: 8),
              Text(
                isReady ? 'FREE TOKEN READY!' : _formatCooldown(_remainingCooldown),
                style: GoogleFonts.sniglet(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isReady
                      ? const Color(0xFF059669)
                      : const Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isReady ? 'Spin to claim your free reward!' : 'Until next free Token.',
          style: GoogleFonts.sniglet(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomEventPill(double dialogWidth) {
    return Container(
      width: dialogWidth,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFB4C4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(22, 22),
            painter: SpinTokenIconPainter(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Find more Spin Tokens in events.',
              style: GoogleFonts.sniglet(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC2185B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GRAND REWARD CLAIM CELEBRATION MODAL
// ============================================================================

class GrandBoosterRewardClaimDialog extends StatefulWidget {
  final BoosterReward reward;
  final VoidCallback onClaim;

  const GrandBoosterRewardClaimDialog({
    super.key,
    required this.reward,
    required this.onClaim,
  });

  @override
  State<GrandBoosterRewardClaimDialog> createState() =>
      _GrandBoosterRewardClaimDialogState();
}

class _GrandBoosterRewardClaimDialogState
    extends State<GrandBoosterRewardClaimDialog>
    with TickerProviderStateMixin {
  late final AnimationController _rayController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF1F4), Color(0xFFFFE4E8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFF4081), width: 3.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4081).withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating Sunburst Rays
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rayController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rayController.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(140, 140),
                            painter: GodRaysPainter(
                              rayCount: 16,
                              color: reward.accentColor.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      },
                    ),

                    // 3D Prize Icon Avatar
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.08),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: reward.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: reward.baseColor.withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            reward.iconEmoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title: "CONGRATULATIONS!"
              Text(
                reward.isJackpot ? 'GRAND JACKPOT!' : 'CONGRATULATIONS!',
                textAlign: TextAlign.center,
                style: GoogleFonts.cherryCreamSoda(
                  fontSize: 22,
                  color: const Color(0xFFC2185B),
                ),
              ),

              const SizedBox(height: 4),

              // Reward Title
              Text(
                reward.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.sniglet(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                reward.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.sniglet(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // CLAIM REWARD Button
              GestureDetector(
                onTap: () {
                  AudioService.instance.playClickSound();
                  HapticFeedback.heavyImpact();
                  widget.onClaim();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CLAIM REWARD',
                      style: GoogleFonts.sniglet(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS: WHEEL (NO TEXT COLLAPSE), BORDER, PEDESTAL, HUB, CHASER
// ============================================================================

/// Wheel Painter with clean, spacious layout (NO text collisions)
class CandyCarnivalWheelPainter extends CustomPainter {
  final List<BoosterReward> rewards;

  CandyCarnivalWheelPainter({required this.rewards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const numSlices = 8;
    const sliceAngle = 2 * math.pi / numSlices;
    final innerRadius = radius - 14.0;

    // 1. Draw 8 wedges
    for (int i = 0; i < numSlices; i++) {
      final reward = rewards[i];
      final startAngle = (i * sliceAngle) - (sliceAngle / 2) - (math.pi / 2);

      // Slices alternating between rich candy pink tones or radiant blue for Jackpot!
      final wedgePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            math.cos(startAngle + sliceAngle / 2) * 0.4,
            math.sin(startAngle + sliceAngle / 2) * 0.4,
          ),
          colors: reward.gradientColors,
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          sliceAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, wedgePaint);

      // Golden wedge separator
      final dividerPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, dividerPaint);

      // Scalloped Golden Cookie Base for the Prize Icon
      final midAngle = startAngle + (sliceAngle / 2);
      final crestRadius = innerRadius - 26;
      final crestPos = Offset(
        center.dx + crestRadius * math.cos(midAngle),
        center.dy + crestRadius * math.sin(midAngle),
      );

      // Golden crest plate
      canvas.drawCircle(
        crestPos,
        18.0,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFD54F), Color(0xFFB45309)],
          ).createShader(Rect.fromCircle(center: crestPos, radius: 18.0)),
      );
      canvas.drawCircle(
        crestPos,
        18.0,
        Paint()
          ..color = const Color(0xFF78350F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Prize Icon inside crest
      final textPainter = TextPainter(
        text: TextSpan(
          text: reward.iconEmoji,
          style: const TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          crestPos.dx - (textPainter.width / 2),
          crestPos.dy - (textPainter.height / 2),
        ),
      );

      // Compact Badge Text (e.g. "500", "2X", "x2", "BOMB") placed safely in outer area
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(midAngle + (math.pi / 2));

      final badgePainter = TextPainter(
        text: TextSpan(
          text: reward.labelShort,
          style: GoogleFonts.sniglet(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Painted comfortably above the crest with zero overlap
      badgePainter.paint(
        canvas,
        Offset(-badgePainter.width / 2, -(innerRadius - 8)),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CandyCarnivalWheelPainter oldDelegate) => false;
}

/// Marquee LED Light bulbs running chaser around the gold rim
class MarqueeChaserRimPainter extends CustomPainter {
  final double chaserProgress;
  final bool isSpinning;

  MarqueeChaserRimPainter({
    required this.chaserProgress,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Heavy 24K Gold Outer Rim
    final goldRimPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFB45309),
          Color(0xFFFFE082),
          Color(0xFFD97706),
          Color(0xFFFFD54F),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;

    canvas.drawCircle(center, radius - 6.0, goldRimPaint);

    // Inner rim accent line
    canvas.drawCircle(
      center,
      radius - 12.0,
      Paint()
        ..color = const Color(0xFF78350F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 2. 16 Marquee Chaser Light Bulbs
    const numBulbs = 16;
    final activeIndex = (chaserProgress * numBulbs).floor() % numBulbs;

    for (int i = 0; i < numBulbs; i++) {
      final angle = i * (2 * math.pi / numBulbs);
      final bulbPos = Offset(
        center.dx + (radius - 6.0) * math.cos(angle),
        center.dy + (radius - 6.0) * math.sin(angle),
      );

      final bool isLit = isSpinning
          ? ((i == activeIndex) || (i == (activeIndex + 1) % numBulbs))
          : (i % 2 == 0);

      if (isLit) {
        canvas.drawCircle(
          bulbPos,
          4.5,
          Paint()
            ..color = const Color(0xFFFFFBEB)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
        );
        canvas.drawCircle(
          bulbPos,
          3.0,
          Paint()..color = const Color(0xFFFFD54F),
        );
      } else {
        canvas.drawCircle(
          bulbPos,
          3.0,
          Paint()..color = const Color(0xFF78350F),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MarqueeChaserRimPainter oldDelegate) =>
      oldDelegate.chaserProgress != chaserProgress ||
      oldDelegate.isSpinning != isSpinning;
}

/// Starburst Golden Hub with center Amber dome
class CandyWheelHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.65;

    // 12-point Golden Starburst Plate
    final starburstPath = Path();
    const points = 12;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        starburstPath.moveTo(x, y);
      } else {
        starburstPath.lineTo(x, y);
      }
    }
    starburstPath.close();

    final starburstPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFFD54F), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));

    canvas.drawPath(starburstPath, starburstPaint);

    // Center 3D Amber Sphere Dome
    final domeRadius = innerR * 0.70;
    final domePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        colors: [
          Color(0xFFFEF3C7),
          Color(0xFFF59E0B),
          Color(0xFFB45309),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: domeRadius));

    canvas.drawCircle(center, domeRadius, domePaint);

    // Specular Highlight
    canvas.drawCircle(
      Offset(center.dx - (domeRadius * 0.3), center.dy - (domeRadius * 0.3)),
      domeRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CandyWheelHubPainter oldDelegate) => false;
}

/// 3D Sculpted Pointer with Ruby Gem Core
class SculptedPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, h)
      ..lineTo(w * 0.08, h * 0.35)
      ..arcToPoint(
        Offset(w * 0.92, h * 0.35),
        radius: Radius.circular(w * 0.45),
      )
      ..close();

    // Drop Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Outer 24K Gold Bezel
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFBEB), Color(0xFFFFD54F), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, goldPaint);

    // Inner Ruby Jewel
    final innerPath = Path()
      ..moveTo(w / 2, h - 4)
      ..lineTo(w * 0.18, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.82, h * 0.38),
        radius: Radius.circular(w * 0.38),
      )
      ..close();

    final rubyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [Color(0xFFFDA4AF), Color(0xFFE11D48), Color(0xFF880E4F)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(innerPath, rubyPaint);

    // Pivot rivet
    final rivetCenter = Offset(w / 2, h * 0.34);
    canvas.drawCircle(rivetCenter, 5.0, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(rivetCenter, 3.5, Paint()..color = const Color(0xFFFFD54F));
  }

  @override
  bool shouldRepaint(covariant SculptedPointerPainter oldDelegate) => false;
}

/// 3D Candy-Blue Pedestal Stand (Matching Image 2)
class BluePedestalPainter extends CustomPainter {
  final bool isGlowing;

  BluePedestalPainter({this.isGlowing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Trapezoid curved base
    final path = Path()
      ..moveTo(w * 0.16, 0)
      ..lineTo(w * 0.84, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFF0369A1).withValues(alpha: 0.35),
    );

    // Sky-Blue Gradient Fill
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
          Color(0xFF0369A1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, basePaint);

    // Top Glossy Highlight Curve
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(w * 0.18, 2), Offset(w * 0.82, 2), highlightPaint);

    // Inner recessed slot for tokens / CTA
    final slotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.54),
        width: w * 0.80,
        height: h * 0.65,
      ),
      const Radius.circular(16),
    );

    final slotPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0284C7), Color(0xFF075985)],
      ).createShader(slotRect.outerRect);

    canvas.drawRRect(slotRect, slotPaint);

    final slotBorderPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(slotRect, slotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant BluePedestalPainter oldDelegate) =>
      oldDelegate.isGlowing != isGlowing;
}

/// 3D Candy Cane Diagonal Striped Border (Matching Image 2)
class CandyCaneBorderPainter extends CustomPainter {
  final double borderWidth;
  final double borderRadius;

  CandyCaneBorderPainter({
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // Diagonal stripes (Candy Pink & White)
    final stripePaint1 = Paint()..color = const Color(0xFFFF8DA1);
    final stripePaint2 = Paint()..color = Colors.white;

    const stripeWidth = 16.0;
    final totalLen = size.width + size.height;

    for (double i = -size.height; i < totalLen; i += stripeWidth * 2) {
      final path1 = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      canvas.drawPath(path1, stripePaint1);

      final path2 = Path()
        ..moveTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth * 2, 0)
        ..lineTo(i + stripeWidth * 2 + size.height, size.height)
        ..lineTo(i + stripeWidth + size.height, size.height)
        ..close();
      canvas.drawPath(path2, stripePaint2);
    }

    // Hollow out inner card body
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        borderWidth,
        borderWidth,
        size.width - (borderWidth * 2),
        size.height - (borderWidth * 2),
      ),
      Radius.circular(borderRadius - borderWidth),
    );

    canvas.drawRRect(innerRRect, Paint()..color = const Color(0xFFFFF6F7));

    // Inner rim stroke
    final innerLinePaint = Paint()
      ..color = const Color(0xFFFFB4C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(innerRRect, innerLinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CandyCaneBorderPainter oldDelegate) => false;
}

/// Hanging String from top screen
class HangingStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4081)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant HangingStringPainter oldDelegate) => false;
}

/// 3D Pink & Gold Spin Token Coin
class SpinTokenIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Pink Outer Coin
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFF80AB), Color(0xFFE91E63), Color(0xFF880E4F)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Inner Gold Rim
    canvas.drawCircle(
      center,
      r - 2.5,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Center Gold Star
    final starPaint = TextPainter(
      text: const TextSpan(
        text: '★',
        style: TextStyle(
          color: Color(0xFFFDE047),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    starPaint.paint(
      canvas,
      Offset(
        center.dx - (starPaint.width / 2),
        center.dy - (starPaint.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SpinTokenIconPainter oldDelegate) => false;
}

/// Golden Stopwatch Icon
class StopwatchIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, (size.height / 2) + 2);
    final r = (size.width / 2) - 3;

    // Top Pusher Button
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, 3),
        width: 6,
        height: 4,
      ),
      Paint()..color = const Color(0xFFD97706),
    );

    // Outer Golden Rim
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFB45309)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // White Dial Face
    canvas.drawCircle(center, r - 3, Paint()..color = Colors.white);

    // Hands
    final handPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx + 4, center.dy - 5), handPaint);
    canvas.drawLine(center, Offset(center.dx - 3, center.dy - 6), handPaint);

    canvas.drawCircle(center, 1.8, Paint()..color = const Color(0xFFD97706));
  }

  @override
  bool shouldRepaint(covariant StopwatchIconPainter oldDelegate) => false;
}

/// God-Rays Rotating Golden Sunburst Halo
class GodRaysPainter extends CustomPainter {
  final int rayCount;
  final Color color;

  GodRaysPainter({
    required this.rayCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angleStep = 2 * math.pi / rayCount;

    final rayPaint = Paint()..color = color;

    for (int i = 0; i < rayCount; i += 2) {
      final startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          angleStep,
          false,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GodRaysPainter oldDelegate) => false;
}

/// Dotted Line Divider
class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter oldDelegate) => false;
}
