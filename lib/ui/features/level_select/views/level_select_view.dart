import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/game/views/game_view.dart';
import 'package:block_bloom/ui/features/garden/widgets/flower_counter_badge.dart';
import 'package:block_bloom/ui/providers.dart';

/// Chapter definition representing a 20-level partition in the Candy Crush style map
class LevelChapter {
  final int number;
  final String title;
  final String subtitle;
  final int startLevel;
  final int endLevel;
  final Color themeColor;
  final Color secondaryColor;
  final String iconEmoji;

  const LevelChapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.startLevel,
    required this.endLevel,
    required this.themeColor,
    required this.secondaryColor,
    required this.iconEmoji,
  });
}

const List<LevelChapter> kLevelChapters = [
  LevelChapter(
    number: 1,
    title: 'Bloom Valley',
    subtitle: 'Spring Blossoms',
    startLevel: 1,
    endLevel: 20,
    themeColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF34D399),
    iconEmoji: '🌸',
  ),
  LevelChapter(
    number: 2,
    title: 'Flora Grove',
    subtitle: 'Enchanted Orchids',
    startLevel: 21,
    endLevel: 40,
    themeColor: Color(0xFF06B6D4),
    secondaryColor: Color(0xFF38BDF8),
    iconEmoji: '🌺',
  ),
  LevelChapter(
    number: 3,
    title: 'Sunburst Meadow',
    subtitle: 'Golden Sunflowers',
    startLevel: 41,
    endLevel: 60,
    themeColor: Color(0xFFF59E0B),
    secondaryColor: Color(0xFFFBBF24),
    iconEmoji: '🌻',
  ),
  LevelChapter(
    number: 4,
    title: 'Petal Paradise',
    subtitle: 'Royal Roses',
    startLevel: 61,
    endLevel: 80,
    themeColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFF472B6),
    iconEmoji: '🌷',
  ),
  LevelChapter(
    number: 5,
    title: 'Blossom Peak',
    subtitle: 'Celestial Sanctuary',
    startLevel: 81,
    endLevel: 100,
    themeColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
    iconEmoji: '👑',
  ),
];

/// Visual decorative scenery element placed along the winding level path (gate, house, tree, flower)
class LevelMapSceneryElement {
  final String asset;
  final double levelAnchor;
  final double xFraction;
  final double width;
  final double height;
  final String tooltip;

  const LevelMapSceneryElement({
    required this.asset,
    required this.levelAnchor,
    required this.xFraction,
    required this.width,
    required this.height,
    required this.tooltip,
  });
}

/// Candy Crush Saga style Winding Level Select View Screen
/// Features:
/// - Opens directly focused on player's existing unlocked level (existing path)
/// - Avatar drop-in bounce entrance animation onto the active level node
/// - Animated travelling light pulse along the existing unlocked path
/// - S-curve cubic bezier path hopping avatar animation when progressing levels
/// - Partitioned in 20/20 level chapters with spacious Candy Crush episode divider gates
/// - Shimmering animated light beam effects on chapter gates
/// - Floating "PLAY LEVEL X" quick-action button at bottom of map
/// - Smooth zoom-in transition when tapping "PLAY NOW" to start a level
class LevelSelectView extends ConsumerStatefulWidget {
  const LevelSelectView({super.key});

  @override
  ConsumerState<LevelSelectView> createState() => _LevelSelectViewState();
}

class _LevelSelectViewState extends ConsumerState<LevelSelectView>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;

  // Pulse animation controller for current active level node
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Avatar entrance drop-in bounce animation controller
  late final AnimationController _avatarEntranceController;
  late final Animation<double> _avatarDropAnimation;

  // Path moving avatar animation controller (Candy Crush style level transition)
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;

  // Shimmer controller for chapter partition gate banners & path energy
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  int _previousUnlockedLevel = 1;
  int _currentUnlockedLevel = 1;

  static const int totalLevels = 100;
  static const int levelsPerChapter = 20;
  static const double stepHeight = 110.0;
  static const double partitionGap = 220.0;
  static const double paddingBottom = 160.0;
  static const double paddingTop = 180.0;
  static const double nodeWidth = 72.0;
  static const double nodeHeight = 62.0;

  late final List<LevelMapSceneryElement> _sceneryElements;

  @override
  void initState() {
    super.initState();

    _sceneryElements = _buildAllMapElements();

    final homeState = ref.read(homeViewModelProvider);
    final unlocked = (homeState.progress?.unlockedLevels ?? 1).clamp(
      1,
      totalLevels,
    );
    _previousUnlockedLevel = unlocked;
    _currentUnlockedLevel = unlocked;

    // Calculate exact screen dimensions to start at the bottom of the map
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    final double screenHeight = view != null && view.physicalSize.height > 0
        ? view.physicalSize.height / view.devicePixelRatio
        : 800.0;

    final double mapHeight = _calculateMapHeight();
    final double bottomOffset = math.max(0.0, mapHeight - screenHeight);

    // Camera starts from the bottom view of the map!
    _scrollController = ScrollController(initialScrollOffset: bottomOffset);

    // Pulse controller for active node
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Avatar drop-in bounce animation (Candy Crush style character drop on map load)
    _avatarEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _avatarDropAnimation = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _avatarEntranceController,
        curve: Curves.bounceOut,
      ),
    );

    // Avatar path moving animation controller (when progressing between levels)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    // Shimmer controller for chapter gate banners & path light pulse
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(homeViewModelProvider.notifier).loadProgress();

      if (mounted) {
        final updatedUnlocked =
            (ref.read(homeViewModelProvider).progress?.unlockedLevels ??
                    unlocked)
                .clamp(1, totalLevels);
        setState(() {
          _previousUnlockedLevel = updatedUnlocked;
          _currentUnlockedLevel = updatedUnlocked;
        });

        // Smoothly and slowly pan upwards from the bottom to that level
        _animateFromBottomToLevel(updatedUnlocked);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _avatarEntranceController.dispose();
    _moveController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  double _calculateMapHeight() {
    return paddingBottom + (99 * stepHeight) + (4 * partitionGap) + paddingTop;
  }

  Offset _getNodePosition(
    int levelIndex,
    double screenWidth,
    double mapHeight,
  ) {
    final int partitionsBefore = (levelIndex - 1) ~/ levelsPerChapter;
    final double distFromBottom =
        ((levelIndex - 1) * stepHeight) + (partitionsBefore * partitionGap);
    final double y = mapHeight - paddingBottom - distFromBottom;

    // Harmonious S-curve alternating Center -> Right -> Center -> Left matching game level screen design
    final double phase = (levelIndex - 1) * (math.pi / 2);
    final double x = screenWidth *
        (0.46 + 0.23 * math.sin(phase) - 0.04 * math.cos(phase).abs());
    return Offset(x, y);
  }

  Offset _getElementPosition(
    double levelAnchor,
    double xFraction,
    double screenWidth,
    double mapHeight,
  ) {
    final int partitionsBefore = (levelAnchor - 1) ~/ levelsPerChapter;
    final double distFromBottom =
        ((levelAnchor - 1) * stepHeight) + (partitionsBefore * partitionGap);
    final double y = mapHeight - paddingBottom - distFromBottom;
    final double x = screenWidth * xFraction;
    return Offset(x, y);
  }

  static List<LevelMapSceneryElement> _buildAllMapElements() {
    final List<LevelMapSceneryElement> elements = [];
    for (int chapter = 0; chapter < 5; chapter++) {
      final double base = chapter * 20.0 + 1.0;
      elements.addAll([
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/gate.png',
          levelAnchor: base + 2.3, // ~ Level 3
          xFraction: 0.63,
          width: 98,
          height: 86,
          tooltip: 'Floral Arch Gate',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/house.png',
          levelAnchor: base + 4.0, // ~ Level 5
          xFraction: 0.18,
          width: 96,
          height: 96,
          tooltip: 'Fairy Blossom Cottage',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/tree.png',
          levelAnchor: base + 5.9, // ~ Level 7
          xFraction: 0.66,
          width: 86,
          height: 88,
          tooltip: 'Enchanted Luminescent Tree',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/flower.png',
          levelAnchor: base + 7.8, // ~ Level 9
          xFraction: 0.22,
          width: 82,
          height: 62,
          tooltip: 'Bloom Valley Blossoms',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/gate.png',
          levelAnchor: base + 10.3, // ~ Level 11
          xFraction: 0.63,
          width: 98,
          height: 86,
          tooltip: 'Floral Arch Gate',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/house.png',
          levelAnchor: base + 12.0, // ~ Level 13
          xFraction: 0.18,
          width: 96,
          height: 96,
          tooltip: 'Fairy Blossom Cottage',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/tree.png',
          levelAnchor: base + 13.9, // ~ Level 15
          xFraction: 0.66,
          width: 86,
          height: 88,
          tooltip: 'Enchanted Luminescent Tree',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/flower.png',
          levelAnchor: base + 15.8, // ~ Level 17
          xFraction: 0.22,
          width: 82,
          height: 62,
          tooltip: 'Bloom Valley Blossoms',
        ),
        LevelMapSceneryElement(
          asset: 'assets/levels_elements/tree.png',
          levelAnchor: base + 17.8, // ~ Level 19
          xFraction: 0.66,
          width: 86,
          height: 88,
          tooltip: 'Enchanted Luminescent Tree',
        ),
      ]);
    }
    return elements;
  }

  double _calculateTargetOffset({
    required int level,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double mapHeight = _calculateMapHeight();
    final Offset nodePos = _getNodePosition(level, screenWidth, mapHeight);
    final double target = nodePos.dy - (screenHeight / 2) + (nodeHeight / 2);
    final double maxScroll = math.max(0.0, mapHeight - screenHeight);
    return target.clamp(0.0, maxScroll);
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double targetOffset = _calculateTargetOffset(
      level: _currentUnlockedLevel,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    final double currentOffset = _scrollController.offset;
    final double distance = (currentOffset - targetOffset).abs();
    final int durationMs = (1500 + (distance * 0.5)).round().clamp(1200, 4000);

    _scrollController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeInOutSine,
    );
  }

  /// Smoothly and slowly pans camera upwards in genuine, ultra-relaxing slow-motion from the bottom
  /// of the map up to that level, then plays the avatar drop-in bounce entrance upon arrival.
  void _animateFromBottomToLevel(int targetLevel) {
    if (!_scrollController.hasClients) return;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double mapHeight = _calculateMapHeight();
    final double bottomOffset = math.max(0.0, mapHeight - screenHeight);

    final double targetOffset = _calculateTargetOffset(
      level: targetLevel,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    // If already at target (e.g. Level 1), bounce immediately
    if ((bottomOffset - targetOffset).abs() < 10) {
      _avatarEntranceController.forward(from: 0.0);
      return;
    }

    // Ensure camera starts at the bottom view
    _scrollController.jumpTo(bottomOffset);

    // Truly slow-motion cinematic upward sweep ("totally slow"):
    // Moves at an ultra-smooth, leisurely pace (~250-350 px/sec)
    // with a base minimum of 7500ms (7.5s) scaling up to 18000ms (18.0s).
    final double distance = (bottomOffset - targetOffset).abs();
    final int durationMs =
        (6000 + (distance * 1.5)).round().clamp(6000, 14000);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController
          .animateTo(
            targetOffset,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeInOutSine,
          )
          .then((_) {
            if (mounted) {
              // Play avatar bounce drop-in right as camera arrives at that level!
              _avatarEntranceController.forward(from: 0.0);
              HapticFeedback.mediumImpact();
            }
          });
    });
  }

  double _getGateCenterY(int gateIndex, double screenWidth, double mapHeight) {
    final int lowerLevel = (gateIndex + 1) * levelsPerChapter;
    final int upperLevel = lowerLevel + 1;
    final double yLower = _getNodePosition(
      lowerLevel,
      screenWidth,
      mapHeight,
    ).dy;
    final double yUpper = _getNodePosition(
      upperLevel,
      screenWidth,
      mapHeight,
    ).dy;
    return (yLower + yUpper) / 2;
  }

  void _checkAndAnimateProgress() {
    final homeState = ref.read(homeViewModelProvider);
    final newUnlocked = (homeState.progress?.unlockedLevels ?? 1).clamp(
      1,
      totalLevels,
    );

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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
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
              border: Border.all(color: const Color(0xFFFFC800), width: 2.0),
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
                          border: Border.all(
                            color: const Color(0xFFFFC800),
                            width: 1.2,
                          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF1A3C0E).withValues(alpha: 0.8)
                        : const Color(0xFF381A00).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFFFFC800),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.star_rounded
                            : Icons.auto_awesome_rounded,
                        color: isCompleted
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFFFC800),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted ? 'COMPLETED' : 'CURRENT LEVEL',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFFFC800),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Board Template Badge
                Builder(
                  builder: (context) {
                    final template = BoardTemplate.getTemplateForLevel(levelNum);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001834),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFC800).withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(template.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            template.name.toUpperCase(),
                            style: GoogleFonts.chakraPetch(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFC800),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${template.rows}x${template.cols}${template.isStandardSquare ? '' : ' Shaped'})',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

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
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                                  '🌸',
                                  style: TextStyle(fontSize: 22),
                                ),
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
                    isCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
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

  void _showChapterInfoDialog(
    LevelChapter chapter,
    bool isUnlocked,
    int unlockedLevels,
  ) {
    AudioService.instance.playClickSound();
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
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
                color: isUnlocked
                    ? chapter.themeColor
                    : const Color(0xFFFFC800),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isUnlocked
                              ? chapter.themeColor
                              : const Color(0xFFFFC800))
                          .withValues(alpha: 0.3),
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
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, chapter.themeColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        'CHAPTER ${chapter.number}',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 22,
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
                          border: Border.all(
                            color: chapter.themeColor,
                            width: 1.2,
                          ),
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

                // Chapter Emoji & Title Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030D19),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: chapter.themeColor.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        chapter.iconEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.title.toUpperCase(),
                        style: GoogleFonts.chakraPetch(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Levels ${chapter.startLevel} - ${chapter.endLevel} • ${chapter.subtitle}',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 13,
                          color: chapter.themeColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isUnlocked
                            ? 'Welcome to ${chapter.title}! Conquer all 20 levels in this zone to gather blooming flowers!'
                            : 'Complete Level ${chapter.startLevel - 1} to break the golden gate and unlock ${chapter.title}!',
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

                const SizedBox(height: 18),

                // Progress Bar in Chapter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chapter Progress:',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      isUnlocked
                          ? '${((unlockedLevels - chapter.startLevel + 1).clamp(0, 20))}/20'
                          : '0/20 (Locked)',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? chapter.themeColor
                            : const Color(0xFFFFB800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isUnlocked
                        ? ((unlockedLevels - chapter.startLevel + 1).clamp(
                                0,
                                20,
                              ) /
                              20.0)
                        : 0.0,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? chapter.themeColor : const Color(0xFFFFB800),
                    ),
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 22),

                // Button
                GreenGameButton(
                  text: isUnlocked ? 'EXPLORE' : 'GOT IT',
                  icon: Icon(
                    isUnlocked ? Icons.play_arrow_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  width: 200.0,
                  height: 48.0,
                  borderRadius: 14.0,
                  fontSize: 15,
                  onPressed: () {
                    AudioService.instance.playClickSound();
                    Navigator.of(ctx).pop();
                    if (isUnlocked && unlockedLevels >= chapter.startLevel) {
                      final double screenHeight = MediaQuery.of(
                        context,
                      ).size.height;
                      final double screenWidth = MediaQuery.of(
                        context,
                      ).size.width;
                      final offset = _calculateTargetOffset(
                        level: chapter.startLevel,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      );
                      _scrollController.animateTo(
                        offset,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                      );
                    }
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

      // Candy Crush style zoom-in transition into the gameplay view
      final result = await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) =>
              GameView(levelNumber: levelNum),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
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
          final updatedUnlocked =
              ref.read(homeViewModelProvider).progress?.unlockedLevels ?? 1;
          if (nextLevelNum <= updatedUnlocked && nextLevelNum <= totalLevels) {
            _showLevelPreviewDialog(
              nextLevelNum,
              isCompleted: nextLevelNum < updatedUnlocked,
            );
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

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final progress = homeState.progress;
    final flowers = progress?.flowers ?? 0;
    final unlockedLevels = (progress?.unlockedLevels ?? 1).clamp(
      1,
      totalLevels,
    );
    final screenSize = MediaQuery.of(context).size;
    final double mapHeight = _calculateMapHeight();

    // Generate positions for all 100 level nodes
    final List<Offset> nodePositions = List.generate(
      totalLevels,
      (index) => _getNodePosition(index + 1, screenSize.width, mapHeight),
    );

    // Positions for previous & current unlocked levels for avatar transition
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
                errorBuilder: (c2, e2, s2) =>
                    Container(color: const Color(0xFF070B19)),
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

          // 2. SCROLLABLE WINDING MAP (S-CURVE PATH + CHAPTER GATES + LEVEL NODES + AVATAR)
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: mapHeight,
              width: screenSize.width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Continuous S-Curve Dotted Map Path Line connecting 1 to 100 with active pulse
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(screenSize.width, mapHeight),
                        painter: LevelPathPainter(
                          points: nodePositions,
                          unlockedIndex: unlockedLevels,
                          pulseProgress: _shimmerAnimation.value,
                        ),
                      );
                    },
                  ),

                  // Decorative Map Scenery Elements (gate, house, tree, flower)
                  for (final element in _sceneryElements)
                    _buildSceneryElement(
                      element: element,
                      screenWidth: screenSize.width,
                      mapHeight: mapHeight,
                    ),

                  // Start Milestone (below Level 1)
                  _buildStartMilestone(context, screenSize.width, mapHeight),

                  // 4 Chapter Partition Gates (between 20 & 21, 40 & 41, 60 & 61, 80 & 81)
                  for (int g = 0; g < 4; g++) ...[
                    _buildChapterGate(
                      context: context,
                      gateIndex: g,
                      gateCenterY: _getGateCenterY(
                        g,
                        screenSize.width,
                        mapHeight,
                      ),
                      screenWidth: screenSize.width,
                      unlockedLevels: unlockedLevels,
                    ),
                  ],

                  // Grand Summit Milestone (above Level 100)
                  _buildSummitMilestone(context, screenSize.width, mapHeight),

                  // All 100 Level Node Buttons
                  for (int i = 0; i < totalLevels; i++) ...[
                    _buildLevelNode(
                      context: context,
                      levelNum: i + 1,
                      position: nodePositions[i],
                      unlockedLevels: unlockedLevels,
                    ),
                  ],

                  // Moving / Hovering Avatar Token (hops along the S-curve path when transitioning)
                  _buildMovingAvatar(
                    prevPos: prevPos,
                    currPos: currPos,
                    unlockedLevels: unlockedLevels,
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING QUICK PLAY BUTTON (Candy Crush / Royal Match style)
          _buildFloatingPlayButton(context, unlockedLevels),

          // 4. TOP OVERLAY HEADER BAR: HOME Back Button + Flower Counter Badge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // HOME Back Button (clean, borderless, circle-free)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AudioService.instance.playClickSound();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                'HOME',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/levels_elements/flower.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text('🌸', style: TextStyle(fontSize: 14)),
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

  /// Floating Quick-Play Button stationed at the bottom of the screen (Candy Crush style)
  Widget _buildFloatingPlayButton(BuildContext context, int unlockedLevels) {
    return Positioned(
      bottom: 22,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            AudioService.instance.playClickSound();
            HapticFeedback.mediumImpact();
            _scrollToCurrentLevel();
            _showLevelPreviewDialog(unlockedLevels, isCompleted: false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF84CC16), Color(0xFF3F6212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFEF08A), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF84CC16).withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  'PLAY LEVEL $unlockedLevels',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
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
    );
  }

  /// Start Milestone Widget (Anchored at the very bottom below Level 1)
  Widget _buildStartMilestone(
    BuildContext context,
    double screenWidth,
    double mapHeight,
  ) {
    final double level1Y = _getNodePosition(1, screenWidth, mapHeight).dy;
    final double cardWidth = math.min(screenWidth * 0.84, 310.0);
    const double cardHeight = 74.0;

    return Positioned(
      left: (screenWidth - cardWidth) / 2,
      top: level1Y + 48.0,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xDD092A20), Color(0xF003150F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                ),
                border: Border.all(color: Colors.white70, width: 1.5),
              ),
              child: const Center(
                child: Text('🌸', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFF6EE7B7)],
                    ).createShader(bounds),
                    child: Text(
                      'START YOUR BLOOM',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chapter 1: Bloom Valley • Levels 1 - 20',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 11,
                      color: const Color(0xFFA7F3D0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.flag_circle_rounded,
              color: Color(0xFF34D399),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  /// Grand Finale Summit Milestone Widget (Anchored above Level 100)
  Widget _buildSummitMilestone(
    BuildContext context,
    double screenWidth,
    double mapHeight,
  ) {
    final double level100Y = _getNodePosition(100, screenWidth, mapHeight).dy;
    final double cardWidth = math.min(screenWidth * 0.86, 320.0);
    const double cardHeight = 84.0;

    return Positioned(
      left: (screenWidth - cardWidth) / 2,
      top: level100Y - 105.0,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xEE2A1E00), Color(0xF5140D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 3,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFD97706)],
                ),
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFFFD700), blurRadius: 10),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFD700)],
                    ).createShader(bounds),
                    child: Text(
                      'MASTER SANCTUARY',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level 100 • Ultimate Garden Champion',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 11,
                      color: const Color(0xFFFDE68A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Text('👑', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  /// Candy Crush Style 20-Level Chapter Partition Gate Divider
  /// Mindblowing Animated and Attractive Design:
  /// - Floating/levitating vertical hover oscillation
  /// - Dynamic glowing neon sweep gradient border tracing around the card
  /// - Breathing aura drop-shadow matching chapter theme colors
  /// - Rotating celestial energy orbital ring around chapter medallion
  /// - Pulsing chapter emblem with floating crown/sparkle badge
  /// - Dual-layer glossy specular shimmer beam sweeping across card surface
  /// - Animated twinkling ✦ starlets at card corners
  /// - Sequentially twinkling golden stars for unlocked chapters
  /// - Pulsing energy glow on progress indicator for locked chapters
  Widget _buildChapterGate({
    required BuildContext context,
    required int gateIndex,
    required double gateCenterY,
    required double screenWidth,
    required int unlockedLevels,
  }) {
    final LevelChapter targetChapter = kLevelChapters[gateIndex + 1];
    final int requiredLevel = targetChapter.startLevel;
    final bool isUnlocked = unlockedLevels >= requiredLevel;

    final double cardWidth = math.min(screenWidth * 0.88, 330.0);
    const double cardHeight = 126.0;

    final Color primaryColor =
        isUnlocked ? targetChapter.themeColor : const Color(0xFFFFB800);
    final Color secondaryColor =
        isUnlocked ? targetChapter.secondaryColor : const Color(0xFFFFE066);

    return Positioned(
      left: (screenWidth - cardWidth) / 2,
      top: gateCenterY - (cardHeight / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            _showChapterInfoDialog(targetChapter, isUnlocked, unlockedLevels),
        child: AnimatedBuilder(
          animation: Listenable.merge([_shimmerAnimation, _pulseController]),
          builder: (context, child) {
            final double shimmerValue = _shimmerAnimation.value;
            final double pulseValue = _pulseController.value;
            final double pulseSin =
                (math.sin(pulseValue * math.pi)).clamp(0.0, 1.0);

            // Subtle floating levitation offset (each gate has slight phase difference)
            final double hoverOffsetY =
                math.sin((pulseValue * 2 * math.pi) + (gateIndex * 1.5)) * 3.5;

            return Transform.translate(
              offset: Offset(0, hoverOffsetY),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. OUTER ROTATING SWEEP GRADIENT BORDER WITH DYNAMIC NEON GLOW
                  Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: SweepGradient(
                        center: Alignment.center,
                        startAngle: 0.0,
                        endAngle: math.pi * 2,
                        transform:
                            GradientRotation(shimmerValue * 2 * math.pi),
                        colors: [
                          primaryColor,
                          secondaryColor,
                          Colors.white.withValues(alpha: 0.85),
                          primaryColor,
                        ],
                        stops: const [0.0, 0.45, 0.65, 1.0],
                      ),
                      boxShadow: [
                        // Animated breathing neon halo
                        BoxShadow(
                          color: primaryColor.withValues(
                            alpha:
                                (isUnlocked ? 0.35 : 0.25) +
                                (0.18 * pulseSin),
                          ),
                          blurRadius: 18.0 + (10.0 * pulseSin),
                          spreadRadius: 1.5 + (1.5 * pulseSin),
                        ),
                        // Ambient dark shadow for depth
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 16,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.0), // Neon border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xF2091D33), Color(0xF7030C18)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // 2. LEFT MEDALLION: CHAPTER EMOJI / LOCK WITH ROTATING ORBITAL AURA
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating orbital energy ring
                              Transform.rotate(
                                angle: -shimmerValue * 2 * math.pi,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        primaryColor.withValues(alpha: 0.8),
                                        Colors.white.withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Inner Medallion Badge
                              Transform.scale(
                                scale: 1.0 + (0.04 * pulseSin),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isUnlocked
                                          ? [primaryColor, secondaryColor]
                                          : [
                                              const Color(0xFF4A2800),
                                              const Color(0xFF1E1002),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: isUnlocked
                                          ? Colors.white
                                          : const Color(0xFFFFD700),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.5 + (0.2 * pulseSin),
                                        ),
                                        blurRadius: 10 + (4 * pulseSin),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isUnlocked
                                        ? Text(
                                            targetChapter.iconEmoji,
                                            style: const TextStyle(
                                              fontSize: 26,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.lock_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 26,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // 3. CENTER / RIGHT INFORMATION
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Tag: Chapter Number & Level Range
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: 0.22,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: primaryColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        'CHAPTER ${targetChapter.number}',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'LV ${targetChapter.startLevel} - ${targetChapter.endLevel}',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Chapter Name
                                Text(
                                  targetChapter.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Status Pill / Progress
                                if (isUnlocked)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF6EE7B7),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CHAPTER UNLOCKED',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6EE7B7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      // 3 Golden Stars with sequential twinkling pulse
                                      for (int s = 0; s < 3; s++) ...[
                                        Transform.scale(
                                          scale: 1.0 +
                                              (0.22 *
                                                  math.max(
                                                    0.0,
                                                    math.sin(
                                                      (shimmerValue +
                                                              (s * 0.33)) *
                                                          2 *
                                                          math.pi,
                                                    ),
                                                  )),
                                          child: const Padding(
                                            padding: EdgeInsets.only(
                                              left: 2.0,
                                            ),
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                else ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.lock_clock_rounded,
                                            color: Color(0xFFFFB800),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Reach Level $requiredLevel',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFB800),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${(unlockedLevels).clamp(0, requiredLevel - 1)}/${requiredLevel - 1}',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (unlockedLevels /
                                              (requiredLevel - 1))
                                          .clamp(0.0, 1.0),
                                      backgroundColor:
                                          const Color(0xFF0F172A),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFB800),
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. ANIMATED CANDY CRUSH SPECULAR SHIMMER LIGHT BEAM
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                -2.4 + (shimmerValue * 3.8),
                                -1.2,
                              ),
                              end: Alignment(
                                -0.6 + (shimmerValue * 3.8),
                                1.2,
                              ),
                              stops: const [0.0, 0.42, 0.50, 0.58, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(
                                  alpha: 0.24,
                                ), // radiant beam
                                Colors.white.withValues(alpha: 0.06),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. ANIMATED TWINKLE SPARKLE ✦ (Top-Right)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: shimmerValue * math.pi,
                        child: Transform.scale(
                          scale: 0.6 +
                              (0.4 *
                                  ((math.sin(
                                            (shimmerValue +
                                                    (gateIndex * 0.2)) *
                                                2 *
                                                math.pi,
                                          ) +
                                          1) /
                                      2)),
                          child: Icon(
                            Icons.auto_awesome,
                            color: secondaryColor.withValues(
                              alpha: 0.6 +
                                  (0.4 *
                                      ((math.sin(
                                                (shimmerValue +
                                                        (gateIndex * 0.2)) *
                                                    2 *
                                                    math.pi,
                                              ) +
                                              1) /
                                          2)),
                            ),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. ANIMATED TWINKLE SPARKLE ✦ (Bottom-Left)
                  Positioned(
                    bottom: -4,
                    left: 20,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -shimmerValue * math.pi,
                        child: Transform.scale(
                          scale: 0.5 +
                              (0.4 *
                                  ((math.sin(
                                            (shimmerValue +
                                                    0.5 +
                                                    (gateIndex * 0.2)) *
                                                2 *
                                                math.pi,
                                          ) +
                                          1) /
                                      2)),
                          child: Icon(
                            Icons.auto_awesome,
                            color: (isUnlocked
                                    ? targetChapter.themeColor
                                    : const Color(0xFFFFD700))
                                .withValues(
                              alpha: 0.5 +
                                  (0.4 *
                                      ((math.sin(
                                                (shimmerValue +
                                                        0.5 +
                                                        (gateIndex * 0.2)) *
                                                    2 *
                                                    math.pi,
                                              ) +
                                              1) /
                                          2)),
                            ),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Evaluates cubic bezier curve position at progress t
  Offset _evaluateCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    final double x =
        uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final double y =
        uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
    return Offset(x, y);
  }

  /// Calculates avatar position along the S-curve path with a natural hopping bounce
  Offset _getAvatarPositionAlongPath(Offset p0, Offset p1, double t) {
    final double controlY = (p0.dy + p1.dy) / 2;
    final Offset cp1 = Offset(p0.dx, controlY);
    final Offset cp2 = Offset(p1.dx, controlY);
    final Offset bezierPos = _evaluateCubicBezier(p0, cp1, cp2, p1, t);
    // Add realistic cartoon hopping bounce as avatar travels along the curve
    final double hop = -math.sin(t * math.pi * 2).abs() * 16.0;
    return Offset(bezierPos.dx, bezierPos.dy + hop);
  }

  /// Moving / Hovering Avatar Indicator stationed at current active unlocked level
  Widget _buildMovingAvatar({
    required Offset prevPos,
    required Offset currPos,
    required int unlockedLevels,
  }) {
    // If transitioning between levels, hop along the exact cubic bezier path curve!
    if (_moveController.isAnimating) {
      return AnimatedBuilder(
        animation: _moveAnimation,
        builder: (context, child) {
          final double t = _moveAnimation.value;
          final Offset pathPos = _getAvatarPositionAlongPath(
            prevPos,
            currPos,
            t,
          );

          return Positioned(
            left: pathPos.dx - 22,
            top: pathPos.dy - 54,
            child: _buildAvatarBadge(),
          );
        },
      );
    }

    // When idle, avatar plays drop-in bounce on entrance, then settles into a gentle breathing bob
    return AnimatedBuilder(
      animation: Listenable.merge([
        _avatarEntranceController,
        _pulseController,
      ]),
      builder: (context, child) {
        final double entranceOffset = _avatarDropAnimation.value;
        final double bobOffset = _avatarEntranceController.isCompleted
            ? math.sin(_pulseController.value * 2 * math.pi) * 4.0
            : 0.0;

        return Positioned(
          left: currPos.dx - 22,
          top: currPos.dy - 54 + entranceOffset + bobOffset,
          child: _buildAvatarBadge(),
        );
      },
    );
  }

  Widget _buildAvatarBadge() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC800), Color(0xFF94C745)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFFC800), blurRadius: 14, spreadRadius: 3),
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.star_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  /// Interactive Decorative Scenery Element (gate.png, house.png, tree.png, flower.png)
  Widget _buildSceneryElement({
    required LevelMapSceneryElement element,
    required double screenWidth,
    required double mapHeight,
  }) {
    final Offset pos = _getElementPosition(
      element.levelAnchor,
      element.xFraction,
      screenWidth,
      mapHeight,
    );

    return Positioned(
      left: pos.dx - (element.width / 2),
      top: pos.dy - (element.height / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          AudioService.instance.playClickSound();
        },
        child: Image.asset(
          element.asset,
          width: element.width,
          height: element.height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Individual Level Node Button
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
    // Locked levels -> level_lock_button.png ONLY
    final String buttonAsset;
    if (isUnlocked) {
      buttonAsset = (levelNum % 2 == 1)
          ? 'assets/level_button1.png'
          : 'assets/level_button2.png';
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

          // 2. Main Level Button Asset Graphic
          Image.asset(
            buttonAsset,
            width: nodeWidth,
            height: nodeHeight,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Container(
              width: nodeWidth,
              height: nodeHeight,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFC800), width: 2),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(
                        '$levelNum',
                        style: const TextStyle(color: Colors.white),
                      )
                    : const Icon(
                        Icons.lock_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
              ),
            ),
          ),

          // 3. Level Number Label (ONLY rendered for unlocked levels)
          if (isUnlocked)
            Positioned(
              top: (nodeHeight * 0.38),
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
      nodeButton = ScaleTransition(scale: _pulseScale, child: nodeButton);
    }

    return Positioned(
      left: position.dx - nodeWidth / 2,
      top: position.dy - nodeHeight / 2,
      child: nodeButton,
    );
  }
}

/// Custom Painter for drawing continuous Candy Crush style S-curve path line connecting all 100 level nodes
class LevelPathPainter extends CustomPainter {
  LevelPathPainter({
    required this.points,
    required this.unlockedIndex,
    required this.pulseProgress,
  });

  final List<Offset> points;
  final int unlockedIndex;
  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Path unlockedPath = Path();
    unlockedPath.moveTo(points[0].dx, points[0].dy);

    final Path lockedPath = Path();
    bool hasLockedSegment = false;

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlY = (p0.dy + p1.dy) / 2;

      // Segments up to the player's current unlocked level
      if (i < unlockedIndex - 1) {
        unlockedPath.cubicTo(p0.dx, controlY, p1.dx, controlY, p1.dx, p1.dy);
      } else {
        if (!hasLockedSegment) {
          lockedPath.moveTo(p0.dx, p0.dy);
          hasLockedSegment = true;
        }
        lockedPath.cubicTo(p0.dx, controlY, p1.dx, controlY, p1.dx, p1.dy);
      }
    }

    // 1. Draw Unlocked Path (Vibrant cyan glow & bright dashes)
    final Paint unlockedGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final Paint unlockedDashPaint = Paint()
      ..color = const Color(0xFFE0F7FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(unlockedPath, unlockedGlowPaint);
    _drawDashedPath(
      canvas,
      unlockedPath,
      unlockedDashPaint,
      dashWidth: 8.0,
      dashSpace: 6.0,
    );

    // 2. Animated Energy Light Pulse flowing along the existing unlocked path towards the current node
    final ui.PathMetrics metrics = unlockedPath.computeMetrics();
    final double totalLen = metrics.fold(0.0, (sum, m) => sum + m.length);
    if (totalLen > 0) {
      final Paint pulsePaint = Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      final double currentPos = (pulseProgress * totalLen) % totalLen;
      const double pulseLen = 28.0;

      for (final metric in unlockedPath.computeMetrics()) {
        if (currentPos < metric.length) {
          final double end = math.min(currentPos + pulseLen, metric.length);
          final Path extract = metric.extractPath(currentPos, end);
          canvas.drawPath(extract, pulsePaint);
        }
      }
    }

    // 3. Draw Locked Path (Subtle, semi-transparent dashed trail ahead)
    if (hasLockedSegment) {
      final Paint lockedGlowPaint = Paint()
        ..color = const Color(0xFF00ACC1).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      final Paint lockedDashPaint = Paint()
        ..color = const Color(0x6680DEEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(lockedPath, lockedGlowPaint);
      _drawDashedPath(
        canvas,
        lockedPath,
        lockedDashPaint,
        dashWidth: 7.0,
        dashSpace: 7.0,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (final ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double extractLength = math.min(
          dashWidth,
          pathMetric.length - distance,
        );
        final Path dashPath = pathMetric.extractPath(
          distance,
          distance + extractLength,
        );
        canvas.drawPath(dashPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter oldDelegate) {
    return oldDelegate.unlockedIndex != unlockedIndex ||
        oldDelegate.points != points ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
