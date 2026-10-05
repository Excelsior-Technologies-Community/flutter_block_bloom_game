import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/game/views/game_view.dart';
import 'package:block_bloom/ui/features/garden/widgets/flower_counter_badge.dart';
import 'package:block_bloom/ui/providers.dart';

/// Candy Crush Saga style Winding Level Select View Screen
/// Features:
/// - Winding S-curve map path with 60 level nodes
/// - Alternating button assets: level_button1.png for Level 1, 3, 5... and level_button2.png for Level 2, 4, 6...
/// - Clean level_lock_button.png for locked nodes (without duplicate lock icon overlay)
/// - Moving avatar token animation along the S-curve path when a level is completed
/// - Pulsating Candy Crush style popping animation on active current level node
/// - Real-time progress synchronization with progress repository & Hive database
/// - Smooth auto-scrolling to user's active unlocked level
class LevelSelectView extends ConsumerStatefulWidget {
  const LevelSelectView({super.key});

  @override
  ConsumerState<LevelSelectView> createState() => _LevelSelectViewState();
}

class _LevelSelectViewState extends ConsumerState<LevelSelectView>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;

  int _previousUnlockedLevel = 1;
  int _currentUnlockedLevel = 1;

  static const int totalLevels = 100;
  static const double stepHeight = 115.0;
  static const double nodeWidth = 72.0;
  static const double nodeHeight = 62.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Pulse animation controller for current active level node
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Path moving avatar animation controller (Candy Crush style level transition)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeState = ref.read(homeViewModelProvider);
      final unlocked = homeState.progress?.unlockedLevels ?? 1;
      _previousUnlockedLevel = unlocked;
      _currentUnlockedLevel = unlocked;

      await ref.read(homeViewModelProvider.notifier).loadProgress();
      _checkAndAnimateProgress();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _checkAndAnimateProgress() {
    final homeState = ref.read(homeViewModelProvider);
    final newUnlocked = homeState.progress?.unlockedLevels ?? 1;

    if (newUnlocked > _currentUnlockedLevel) {
      setState(() {
        _previousUnlockedLevel = _currentUnlockedLevel;
        _currentUnlockedLevel = newUnlocked;
      });
      _moveController.forward(from: 0.0);
    } else {
      setState(() {
        _previousUnlockedLevel = newUnlocked;
        _currentUnlockedLevel = newUnlocked;
      });
    }
    _scrollToCurrentLevel();
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double paddingBottom = 160.0;
    final double mapHeight = totalLevels * stepHeight + paddingBottom + 120.0;

    final double currentLevelY = mapHeight - paddingBottom - ((_currentUnlockedLevel - 1) * stepHeight);
    final double targetOffset = (currentLevelY - screenHeight / 2 + nodeHeight / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
  }

  void _onNodeTap(int levelNum, int unlockedLevels) {
    if (levelNum > unlockedLevels) {
      AudioService.instance.playClickSound();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete Level ${levelNum - 1} to unlock Level $levelNum!',
            style: GoogleFonts.chakraPetch(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    AudioService.instance.playClickSound();
    _showLevelPreviewDialog(levelNum, isCompleted: levelNum < unlockedLevels);
  }

  void _showLevelPreviewDialog(int levelNum, {required bool isCompleted}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF092038), Color(0xFF041223)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFC800),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC800).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Level Title + Close 'X' Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFD700)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        'LEVEL $levelNum',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AudioService.instance.playClickSound();
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F).withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFC800), width: 1.2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status Badge (COMPLETED vs CURRENT LEVEL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF1A3C0E).withValues(alpha: 0.8)
                        : const Color(0xFF381A00).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF6EE7B7) : const Color(0xFFFFC800),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.star_rounded : Icons.auto_awesome_rounded,
                        color: isCompleted ? const Color(0xFF6EE7B7) : const Color(0xFFFFC800),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted ? 'COMPLETED' : 'CURRENT LEVEL',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? const Color(0xFF6EE7B7) : const Color(0xFFFFC800),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Objective Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030D19),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1E3A5F),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/game_flower.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text('🌸', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCompleted ? 'Replay Goal' : 'Target Goal',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8EA2C0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCompleted
                            ? 'Replay Level $levelNum to earn more flowers and beat your high score!'
                            : 'Clear lines, trigger combos & bloom flowers to complete Level $levelNum!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.chakraPetch(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Green Candy Crush Style Play Button
                GreenGameButton(
                  text: isCompleted ? 'PLAY AGAIN' : 'PLAY NOW',
                  icon: Icon(
                    isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  width: 220.0,
                  height: 52.0,
                  borderRadius: 16.0,
                  fontSize: 16,
                  onPressed: () {
                    AudioService.instance.playClickSound();
                    Navigator.of(ctx).pop();
                    _startLevel(levelNum);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startLevel(int levelNum) async {
    final homeState = ref.read(homeViewModelProvider);
    final unlockedLevels = homeState.progress?.unlockedLevels ?? 1;

    if (levelNum <= unlockedLevels) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playClickSound();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameView(levelNumber: levelNum),
        ),
      );

      // Reload progress when returning from GameView
      await ref.read(homeViewModelProvider.notifier).loadProgress();
      _checkAndAnimateProgress();

      if (result == 'next_level') {
        final nextLevelNum = levelNum + 1;
        // Wait for map level redirection avatar animation (1.4s) to complete
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          final updatedUnlocked = ref.read(homeViewModelProvider).progress?.unlockedLevels ?? 1;
          if (nextLevelNum <= updatedUnlocked && nextLevelNum <= totalLevels) {
            _showLevelPreviewDialog(nextLevelNum, isCompleted: nextLevelNum < updatedUnlocked);
          }
        }
      }
    } else {
      AudioService.instance.playClickSound();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Complete Level ${levelNum - 1} to unlock Level $levelNum!',
              style: GoogleFonts.chakraPetch(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Offset _getNodePosition(int levelIndex, double screenWidth, double mapHeight) {
    const double paddingBottom = 160.0;
    final double y = mapHeight - paddingBottom - ((levelIndex - 1) * stepHeight);
    final double amplitude = screenWidth * 0.28;
    final double centerX = screenWidth / 2;
    final double x = centerX + amplitude * math.sin(levelIndex * 0.72);
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final progress = homeState.progress;
    final flowers = progress?.flowers ?? 0;
    final unlockedLevels = progress?.unlockedLevels ?? 1;
    final screenSize = MediaQuery.of(context).size;
    final double mapHeight = totalLevels * stepHeight + 280.0;

    // Generate positions for all level nodes
    final List<Offset> nodePositions = List.generate(
      totalLevels,
      (index) => _getNodePosition(index + 1, screenSize.width, mapHeight),
    );

    // Interpolate moving avatar position between previous & current unlocked level
    final int prevIdx = (_previousUnlockedLevel - 1).clamp(0, totalLevels - 1);
    final int currIdx = (_currentUnlockedLevel - 1).clamp(0, totalLevels - 1);
    final Offset prevPos = nodePositions[prevIdx];
    final Offset currPos = nodePositions[currIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF05001C),
      body: Stack(
        children: [
          // 1. FULLSCREEN MAP BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/level.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/splash_img.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (c2, e2, s2) => Container(color: const Color(0xFF070B19)),
              ),
            ),
          ),

          // Dark Subtle Gradient Vignette
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x7705001C),
                    Color(0x2205001C),
                    Color(0x8805001C),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. SCROLLABLE WINDING MAP (S-CURVE PATH + LEVEL NODES + MOVING AVATAR)
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: mapHeight,
              width: screenSize.width,
              child: Stack(
                children: [
                  // S-Curve Dotted Map Path Line
                  CustomPaint(
                    size: Size(screenSize.width, mapHeight),
                    painter: LevelPathPainter(
                      points: nodePositions,
                      unlockedIndex: unlockedLevels,
                    ),
                  ),

                  // Level Node Buttons
                  for (int i = 0; i < totalLevels; i++) ...[
                    _buildLevelNode(
                      context: context,
                      levelNum: i + 1,
                      position: nodePositions[i],
                      unlockedLevels: unlockedLevels,
                    ),
                  ],

                  // Moving Avatar Indicator (Candy Crush transition animation between levels)
                  if (_moveController.isAnimating || _previousUnlockedLevel != _currentUnlockedLevel)
                    AnimatedBuilder(
                      animation: _moveAnimation,
                      builder: (context, child) {
                        final double t = _moveAnimation.value;
                        final double currentX = ui.lerpDouble(prevPos.dx, currPos.dx, t)!;
                        final double currentY = ui.lerpDouble(prevPos.dy, currPos.dy, t)!;

                        return Positioned(
                          left: currentX - 22,
                          top: currentY - 54,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFC800), Color(0xFF94C745)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              border: Border.all(color: Colors.white, width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFFFC800),
                                  blurRadius: 14,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // 3. TOP OVERLAY HEADER BAR: HOME Back Button + Flower Counter Badge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // HOME Back Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AudioService.instance.playClickSound();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x99001126),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFC800).withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                'HOME',
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
                      ),
                    ),

                    const Spacer(),

                    // Flower Counter Badge
                    FlowerCounterBadge(count: flowers),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode({
    required BuildContext context,
    required int levelNum,
    required Offset position,
    required int unlockedLevels,
  }) {
    final bool isUnlocked = levelNum <= unlockedLevels;
    final bool isCurrent = levelNum == unlockedLevels;

    // Asset selection:
    // Level 1, 3, 5... -> level_button1.png
    // Level 2, 4, 6... -> level_button2.png
    // Locked levels -> level_lock_button.png ONLY (no double lock icon!)
    final String buttonAsset;
    if (isUnlocked) {
      buttonAsset = (levelNum % 2 == 1) ? 'assets/level_button1.png' : 'assets/level_button2.png';
    } else {
      buttonAsset = 'assets/level_lock_button.png';
    }

    Widget nodeButton = GestureDetector(
      onTap: () => _onNodeTap(levelNum, unlockedLevels),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Glowing active ring behind current level button
          if (isCurrent)
            ScaleTransition(
              scale: _pulseScale,
              child: Container(
                width: nodeWidth + 14,
                height: nodeHeight + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.65),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF94C745).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

          // 2. Main Level Button Asset Graphic (No duplicate lock icon overlay for locked nodes!)
          Image.asset(
            buttonAsset,
            width: nodeWidth,
            height: nodeHeight,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Container(
              width: nodeWidth,
              height: nodeHeight,
              decoration: BoxDecoration(
                color: isUnlocked ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFC800), width: 2),
              ),
              child: Center(
                child: isUnlocked
                    ? Text('$levelNum', style: const TextStyle(color: Colors.white))
                    : const Icon(Icons.lock_rounded, color: Colors.white54, size: 20),
              ),
            ),
          ),

          // 3. Level Number Label (ONLY rendered for unlocked levels!)
          if (isUnlocked)
            Positioned(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFFFE082)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  '$levelNum',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                      Shadow(
                        color: Color(0xFF000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Apply popping Candy Crush animation scale to current active node
    if (isCurrent) {
      nodeButton = ScaleTransition(
        scale: _pulseScale,
        child: nodeButton,
      );
    }

    return Positioned(
      left: position.dx - nodeWidth / 2,
      top: position.dy - nodeHeight / 2,
      child: nodeButton,
    );
  }
}

/// Custom Painter for drawing Candy Crush style S-curve path line connecting level nodes
class LevelPathPainter extends CustomPainter {
  LevelPathPainter({
    required this.points,
    required this.unlockedIndex,
  });

  final List<Offset> points;
  final int unlockedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlY = (p0.dy + p1.dy) / 2;
      path.cubicTo(
        p0.dx,
        controlY,
        p1.dx,
        controlY,
        p1.dx,
        p1.dy,
      );
    }

    // Outer glow cyan line
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Dashed inner cyan path line
    final Paint dashPaint = Paint()
      ..color = const Color(0xFF80DEEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);

    // Draw dashed path
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (final ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      const double dashWidth = 8.0;
      const double dashSpace = 6.0;

      while (distance < pathMetric.length) {
        final double extractLength = math.min(dashWidth, pathMetric.length - distance);
        final Path dashPath = pathMetric.extractPath(distance, distance + extractLength);
        canvas.drawPath(dashPath, dashPaint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter oldDelegate) {
    return oldDelegate.unlockedIndex != unlockedIndex || oldDelegate.points != points;
  }
}
