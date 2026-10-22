import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';

/// Responsive, overflow-proof Candy Crush Saga styled Level Popup Modal for Block Bloom.
///
/// Features:
/// 1. Rotating Golden Sunburst (God-Rays) and floating blossom sparkles.
/// 2. 3D Perspective Spring-Tilt Card Entrance.
/// 3. Animated Grand Blooming Flower Crest (Bloom Emblem with elastic bounce & petal pulse).
/// 4. Responsive Target Score Progress Bar with milestone fill (0% .. 100%+).
/// 5. Live Miniature Visual Board Preview rendering the real playable cell shape.
/// 6. Interactive Pre-Game Booster Capsules (Expanded responsive flex layout).
/// 7. Grand 3D Green Play Button with continuous diagonal light sheen beam sweep.
/// 8. Overhanging Candy Ribbon Banner ("LEVEL X") with light shimmer sweep.
/// 9. 100% Overflow-proof with SafeArea, SingleChildScrollView, and Flexible widgets.
class CandyCrushLevelPopup extends StatefulWidget {
  const CandyCrushLevelPopup({
    super.key,
    required this.levelNum,
    required this.isCompleted,
    required this.template,
    required this.targetScore,
    this.bestScore,
    required this.onPlay,
    required this.onClose,
  });

  final int levelNum;
  final bool isCompleted;
  final BoardTemplate template;
  final int targetScore;
  final int? bestScore;
  final VoidCallback onPlay;
  final VoidCallback onClose;

  /// Helper method to open the Candy Crush level dialog with custom spring transition
  static Future<void> show({
    required BuildContext context,
    required int levelNum,
    required bool isCompleted,
    required BoardTemplate template,
    required int targetScore,
    int? bestScore,
    required VoidCallback onPlay,
  }) {
    HapticFeedback.heavyImpact();
    AudioService.instance.playClickSound();

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CandyCrushLevelPopup',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 440),
      pageBuilder: (ctx, anim1, anim2) {
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Material(
                color: Colors.transparent,
                child: CandyCrushLevelPopup(
                  levelNum: levelNum,
                  isCompleted: isCompleted,
                  template: template,
                  targetScore: targetScore,
                  bestScore: bestScore,
                  onPlay: () {
                    Navigator.of(ctx).pop();
                    onPlay();
                  },
                  onClose: () {
                    Navigator.of(ctx).pop();
                  },
                ),
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
            sigmaX: 6.0 * animation.value,
            sigmaY: 6.0 * animation.value,
          ),
          child: FadeTransition(
            opacity: animation,
            child: Transform.scale(
              scale: curved.value.clamp(0.01, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX((1.0 - curved.value) * 0.18),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CandyCrushLevelPopup> createState() => _CandyCrushLevelPopupState();
}

class _CandyCrushLevelPopupState extends State<CandyCrushLevelPopup>
    with TickerProviderStateMixin {
  // 1. Sunburst God-Rays Rotating Controller
  late final AnimationController _rayController;

  // 2. Blooming Flower Emblem Bounce & Petal Expansion Controller
  late final AnimationController _bloomController;

  // 3. Score Progress Gauge Fill-up Controller
  late final AnimationController _progressController;

  // 4. Shimmer Sheen & Breathing Pulse Controller
  late final AnimationController _shimmerController;

  // Track which pre-game boosters player selected
  final Set<String> _selectedBoosters = {'sun'};

  @override
  void initState() {
    super.initState();

    // 1. God Rays Continuous Rotation (16s per cycle)
    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // 2. Flower Bloom Bounce Controller
    _bloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 3. Score Bar Fill Animation Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 4. Shimmer & Button Heartbeat Pulse Controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Start bloom animations with slight delay for dramatic entrance
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _bloomController.forward();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _rayController.dispose();
    _bloomController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // -------------------------------------------------------------
            // LAYER 0: ROTATING GOLDEN SUNBURST GOD-RAYS (Cinematic Halo)
            // -------------------------------------------------------------
            Positioned(
              top: -60,
              child: AnimatedBuilder(
                animation: _rayController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rayController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: const Size(400, 400),
                  painter: _SunburstPainter(
                    rayCount: 16,
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------------
            // LAYER 1: MAIN POPUP CARD BODY
            // -------------------------------------------------------------
            Container(
              margin: const EdgeInsets.only(top: 22),
              padding: const EdgeInsets.fromLTRB(14, 32, 14, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D2847),
                    Color(0xFF091C33),
                    Color(0xFF040E1B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFFFD54F),
                  width: 2.8,
                ),
                boxShadow: [
                  // Golden ambient bloom
                  BoxShadow(
                    color: const Color(0xFFFFC800).withValues(alpha: 0.40),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                  // Deep drop shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.80),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),

                  // 1. GRAND FLOWER BLOOM CREST (The central heroic visual!)
                  _buildGrandFlowerBloomCrest(),

                  const SizedBox(height: 10),

                  // 2. CANDY CRUSH TARGET SCORE PROGRESS BAR
                  _buildScoreProgressTube(),

                  const SizedBox(height: 10),

                  // 3. LIVE MINIATURE VISUAL BOARD PREVIEW & OBJECTIVE CARD
                  _buildBoardPreviewAndObjective(),

                  const SizedBox(height: 10),

                  // 4. INTERACTIVE PRE-GAME GARDEN BOOSTERS
                  _buildInteractiveBoosters(),

                  const SizedBox(height: 14),

                  // 5. GRAND SHIMMERING 3D PLAY BUTTON
                  _buildGrandPlayButton(),
                ],
              ),
            ),

            // -------------------------------------------------------------
            // LAYER 2: OVERHANGING CURVED RIBBON BANNER ("LEVEL X")
            // -------------------------------------------------------------
            Positioned(
              top: 0,
              child: _buildCandyRibbonBanner(),
            ),

            // -------------------------------------------------------------
            // LAYER 3: 3D CANDY CLOSE "X" BUTTON (Top-Right Burst)
            // -------------------------------------------------------------
            Positioned(
              top: 6,
              right: -6,
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET & EFFECT BUILDERS
  // =========================================================================

  /// Overhanging Candy Crush Celebratory Ribbon with light sheen sweep
  Widget _buildCandyRibbonBanner() {
    return SizedBox(
      width: 240,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left folded fishtail wing
          Positioned(
            left: 2,
            bottom: 4,
            child: _buildRibbonFishtail(isLeft: true),
          ),

          // Right folded fishtail wing
          Positioned(
            right: 2,
            bottom: 4,
            child: _buildRibbonFishtail(isLeft: false),
          ),

          // Center Ribbon Plaque
          Container(
            width: 196,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF2A6D),
                  Color(0xFFC2185B),
                  Color(0xFF880E4F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFE082),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withValues(alpha: 0.65),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Diagonal Sheen Light Sweep
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      final pos = -100 + (_shimmerController.value * 300);
                      return Positioned(
                        left: pos,
                        top: -10,
                        bottom: -10,
                        width: 40,
                        child: Transform.rotate(
                          angle: 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Top Glossy Highlight arc
                  Positioned(
                    top: 2,
                    left: 10,
                    right: 10,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Ribbon Title Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🌸',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFFFE082),
                                Color(0xFFFFB300),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              'LEVEL ${widget.levelNum}',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xAA000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '🌸',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonFishtail({required bool isLeft}) {
    return Transform.rotate(
      angle: isLeft ? -0.16 : 0.16,
      child: Container(
        width: 30,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF880E4F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFFB300),
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Grand Flower Bloom Crest (Heroic Garden Emblem)
  Widget _buildGrandFlowerBloomCrest() {
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bloomController,
        curve: Curves.elasticOut,
      ),
    );

    return AnimatedBuilder(
      animation: _bloomController,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value.clamp(0.0, 1.2),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing Flower Medallion
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Golden Halo
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD54F).withValues(alpha: 0.35),
                      const Color(0xFFFF8F00).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.30),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),

              // Medallion Circle
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF1B4D7E),
                      Color(0xFF0E2E52),
                      Color(0xFF06182D),
                    ],
                    center: Alignment(-0.25, -0.35),
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 2.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/game_flower.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => Image.asset(
                      'assets/levels_elements/flower.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx2, err2, st2) => const Text(
                        '🌸',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Level Status Badge (COMPLETED vs CURRENT)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? const Color(0xFF143B1A).withValues(alpha: 0.9)
                  : const Color(0xFF381B00).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isCompleted
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFFFC800),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isCompleted
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFFC800))
                      .withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.local_fire_department_rounded,
                    color: widget.isCompleted
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFFFFD54F),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.isCompleted ? 'LEVEL COMPLETED' : 'READY TO BLOOM',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: widget.isCompleted
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFFD54F),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Candy Crush Target Score Progress Tube (Responsive & Overflow-proof)
  Widget _buildScoreProgressTube() {
    final bestScore = widget.bestScore ?? 0;
    final progressFraction = widget.targetScore > 0
        ? (bestScore / widget.targetScore).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final animatedFill = progressFraction * _progressController.value;
        final currentAnimatedScore =
            (bestScore * _progressController.value).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF040E1B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E3A5F),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              // Score Numbers Row with Flex scaling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFD54F),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BEST: ',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '${_formatScore(currentAnimatedScore)} PTS',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.track_changes_rounded,
                            color: Color(0xFF6EE7B7),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TARGET: ',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            _formatScore(widget.targetScore),
                            style: GoogleFonts.chakraPetch(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Liquid Gold / Emerald Progress Tube
              LayoutBuilder(
                builder: (context, constraints) {
                  final tubeWidth = constraints.maxWidth;
                  return SizedBox(
                    height: 12,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Outer Tube Track
                        Container(
                          height: 10,
                          width: tubeWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFF08182B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF1A385C),
                              width: 1.0,
                            ),
                          ),
                        ),

                        // Liquid Fill Bar
                        Container(
                          width: (tubeWidth * animatedFill).clamp(4.0, tubeWidth),
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isCompleted
                                  ? const [
                                      Color(0xFF10B981),
                                      Color(0xFF34D399),
                                      Color(0xFF6EE7B7),
                                    ]
                                  : const [
                                      Color(0xFFFFB300),
                                      Color(0xFFFFD54F),
                                      Color(0xFFFFF59D),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isCompleted
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFFFC800))
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Live Miniature Visual Board Preview + Objective info
  Widget _buildBoardPreviewAndObjective() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF030D19),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A5F),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Real Miniature Board Layout Grid Preview
          _buildMiniBoardPreview(),

          const SizedBox(width: 10),

          // Right: Board Name, Emoji, Dimensions & Goal description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.template.emoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.template.name.toUpperCase(),
                        style: GoogleFonts.chakraPetch(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD54F),
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.template.rows}x${widget.template.cols} ${widget.template.isStandardSquare ? 'Classic Grid' : 'Shaped Arena'}',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isCompleted
                        ? const Color(0xFF143B1A)
                        : const Color(0xFF381B00),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isCompleted
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFFC800),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isCompleted ? '✓ LEVEL CONQUERED' : '🎯 GOAL: REACH TARGET',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: widget.isCompleted
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFFFC800),
                        letterSpacing: 0.5,
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
  }

  /// Live Mini Board Layout Grid showing exact playable cell shapes
  Widget _buildMiniBoardPreview() {
    const miniSize = 52.0;

    return Container(
      width: miniSize,
      height: miniSize,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF08182B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(44, 44),
          painter: _MiniBoardPainter(
            template: widget.template,
            playableColor: const Color(0xFF38BDF8),
          ),
        ),
      ),
    );
  }

  /// Interactive Pre-Game Booster Capsules (Expanded Layout to prevent overflow)
  Widget _buildInteractiveBoosters() {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFD54F),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                'EQUIP PRE-LEVEL POWERS',
                style: GoogleFonts.chakraPetch(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFD54F),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildSelectableBooster(
                id: 'sun',
                emoji: '🌻',
                name: 'Sun Surge',
                detail: '2x Score',
                glowColor: const Color(0xFFFFC800),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSelectableBooster(
                id: 'refresh',
                emoji: '💧',
                name: 'Refresh',
                detail: 'Reshuffle',
                glowColor: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSelectableBooster(
                id: 'bomb',
                emoji: '💣',
                name: 'Bloom Bomb',
                detail: 'Explosive',
                glowColor: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectableBooster({
    required String id,
    required String emoji,
    required String name,
    required String detail,
    required Color glowColor,
  }) {
    final isSelected = _selectedBoosters.contains(id);

    return GestureDetector(
      onTap: () {
        AudioService.instance.playClickSound();
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedBoosters.remove(id);
          } else {
            _selectedBoosters.add(id);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSelected
                  ? '$emoji $name unequipped.'
                  : '✨ $emoji $name EQUIPPED! Line clears will activate this power.',
              style: GoogleFonts.chakraPetch(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0F2642),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      },
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 0.98,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF08223F)
                : const Color(0xFF041223),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? glowColor : const Color(0xFF1E3A5F),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Active / Ready Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? glowColor.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isSelected ? '✓ ACTIVE' : detail,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? glowColor : Colors.white60,
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

  /// Grand 3D Green Play Button with continuous light sheen sweep & pulse
  Widget _buildGrandPlayButton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final breathingScale = 1.0 + (math.sin(_shimmerController.value * math.pi * 2) * 0.030);
        return Transform.scale(
          scale: breathingScale,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing pulse ring
          Container(
            width: 236,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF94C745).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Green Game Button
          GreenGameButton(
            text: widget.isCompleted ? 'PLAY AGAIN' : 'PLAY NOW',
            icon: Icon(
              widget.isCompleted
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 26,
            ),
            width: 226.0,
            height: 50.0,
            borderRadius: 14.0,
            fontSize: 17,
            onPressed: () {
              AudioService.instance.playClickSound();
              HapticFeedback.heavyImpact();
              widget.onPlay();
            },
          ),
        ],
      ),
    );
  }

  /// 3D Candy Close Button (top-right bursting out)
  Widget _buildCloseButton() {
    return _Candy3DCloseButton(
      onPressed: () {
        AudioService.instance.playClickSound();
        widget.onClose();
      },
    );
  }
}

/// Rotating Sunburst God-Rays Painter
class _SunburstPainter extends CustomPainter {
  final int rayCount;
  final Color color;

  _SunburstPainter({required this.rayCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final step = (2 * math.pi) / rayCount;
    for (int i = 0; i < rayCount; i += 2) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          i * step,
          step,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) => false;
}

/// Renders a mathematically scaled, overflow-proof mini board preview
class _MiniBoardPainter extends CustomPainter {
  final BoardTemplate template;
  final Color playableColor;

  _MiniBoardPainter({
    required this.template,
    required this.playableColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = template.rows;
    final cols = template.cols;
    if (rows <= 0 || cols <= 0) return;

    const cellSpacing = 1.0;
    final maxCellW = (size.width - ((cols - 1) * cellSpacing)) / cols;
    final maxCellH = (size.height - ((rows - 1) * cellSpacing)) / rows;
    final cellSize = math.min(maxCellW, maxCellH);

    final gridW = cols * cellSize + (cols - 1) * cellSpacing;
    final gridH = rows * cellSize + (rows - 1) * cellSpacing;

    final startX = (size.width - gridW) / 2;
    final startY = (size.height - gridH) / 2;

    final playablePaint = Paint()
      ..color = playableColor
      ..style = PaintingStyle.fill;

    final emptyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final radius = Radius.circular(math.max(1.0, cellSize * 0.22));

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          startX + c * (cellSize + cellSpacing),
          startY + r * (cellSize + cellSpacing),
          cellSize,
          cellSize,
        );
        final rrect = RRect.fromRectAndRadius(rect, radius);
        if (template.isPlayable(r, c)) {
          canvas.drawRRect(rrect, playablePaint);
        } else {
          canvas.drawRRect(rrect, emptyPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBoardPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.playableColor != playableColor;
  }
}

/// Tactile 3D Candy-Styled Close "X" Button
class _Candy3DCloseButton extends StatefulWidget {
  const _Candy3DCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_Candy3DCloseButton> createState() => _Candy3DCloseButtonState();
}

class _Candy3DCloseButtonState extends State<_Candy3DCloseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3366), Color(0xFFC2185B), Color(0xFF880E4F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFE082),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 2,
                left: 6,
                right: 6,
                height: 11,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
