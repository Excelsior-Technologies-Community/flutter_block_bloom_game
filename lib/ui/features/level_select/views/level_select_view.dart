import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/domain/use_cases/level_generator.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/game/views/game_view.dart';
import 'package:block_bloom/ui/features/garden/widgets/flower_counter_badge.dart';
import 'package:block_bloom/ui/features/level_select/widgets/candy_crush_level_popup.dart';
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

  // Cloud controller for dreamy horizontal drifting clouds layer
  late final AnimationController _cloudController;
  late final Animation<double> _cloudAnimation;

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

    // Avatar path moving animation controller (slow, smooth, leisurely transition)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
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

    // Cloud controller for gentle drifting cloudscape (45-second relaxing cycle)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    _cloudAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cloudController, curve: Curves.linear),
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
    _cloudController.dispose();
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
    // Smooth, slow-motion camera gliding that matches the avatar hop
    final int durationMs = (3000 + (distance * 1.0)).round().clamp(3000, 5500);

    _scrollController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeInOutCubic,
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
    final homeState = ref.read(homeViewModelProvider);
    final userProgress = homeState.progress;
    final bestScore = userProgress?.bestScore[levelNum];
    final template = BoardTemplate.getTemplateForLevel(levelNum);
    final targetScore =
        LevelGenerator.getTargetScoreForLevel(levelNum, template.rows);

    CandyCrushLevelPopup.show(
      context: context,
      levelNum: levelNum,
      isCompleted: isCompleted,
      template: template,
      targetScore: targetScore,
      bestScore: bestScore,
      onPlay: () {
        _startLevel(levelNum);
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
        // Wait for slow-motion map avatar hop & camera pan (3.5s) to complete
        await Future.delayed(const Duration(milliseconds: 3500));
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
          // 1. FULLSCREEN MAP BACKGROUND (Always covers 100% of the screen from start to end)
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

          // Ambient Drifting Stylized Clouds (Candy Crush Saga atmosphere)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _cloudAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: screenSize,
                    painter: AmbientCloudsPainter(
                      progress: _cloudAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Ambient Floating Magical Fireflies / Fairy Motes (Candy Crush / Gardenscapes aesthetic)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: screenSize,
                    painter: AmbientFirefliesPainter(
                      progress: _shimmerAnimation.value,
                    ),
                  );
                },
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
                  _buildStartMilestone(
                    context,
                    screenSize.width,
                    mapHeight,
                  ),

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
                      mapHeight: mapHeight,
                      unlockedLevels: unlockedLevels,
                    ),
                  ],

                  // Grand Summit Milestone (above Level 100)
                  _buildSummitMilestone(
                    context,
                    screenSize.width,
                    mapHeight,
                  ),

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
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFFFC610),
                                    ],
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
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFFFC610),
                                    ],
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
  /// Chapter 1 Start Milestone styled with exact Figma specifications (200 Hug x 71.5 Hug)
  Widget _buildStartMilestone(
    BuildContext context,
    double screenWidth,
    double mapHeight,
  ) {
    final double level1Y = _getNodePosition(1, screenWidth, mapHeight).dy;
    final LevelChapter chapter1 = kLevelChapters[0];
    final double cardWidth = math.min(212.0, screenWidth - 36.0);
    const double cardHeight = 78.0;

    return Positioned(
      left: (screenWidth - cardWidth) / 2,
      top: level1Y + 52.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.playClickSound();
          HapticFeedback.lightImpact();
          _showChapterInfoDialog(chapter1, true, 100);
        },
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFC800),
                Color(0xFF814D00),
                Color(0xFF6B4000),
                Color(0xFF814D00),
                Color(0xFFFFC800),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A79B6).withValues(alpha: 0.55),
                blurRadius: 1.63,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF7A79B6).withValues(alpha: 0.38),
                blurRadius: 22.85,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.0), // Figma 1px border
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Figma padding: 10px
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF001834), // Figma Fill: #001834
              borderRadius: BorderRadius.circular(9),
              image: const DecorationImage(
                image: AssetImage('assets/leaderboard_icons/back_design.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                colorFilter: ColorFilter.mode(
                  Color(0xFF001834),
                  BlendMode.modulate,
                ),
              ),
            ),
            child: Row(
              children: [
                // LEFT COLUMN
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001834),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFC800),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'CHAPTER 1',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 18,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              chapter1.title.toUpperCase(),
                              style: GoogleFonts.chakraPetch(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF00E676),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'CHAPTER UNLOCKED',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00E676),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // RIGHT COLUMN: 3 STARS + LEVEL RANGE
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int s = 0; s < 3; s++) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC800),
                              size: 15,
                            ),
                            if (s < 2) const SizedBox(width: 2),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'LV 1 - 20',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.4,
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
  /// - Pulsing energy glow on progres  /// Chapter Gate Card designed according to exact Figma specifications:
  /// - Dimensions: Width: Hug (200px), Height: Hug (71.5px)
  /// - Radius: 10px
  /// - Border: 1px Linear Gradient [#FFC800, #814D00, #6B4000, #814D00, #FFC800]
  /// - Padding: 10px, Gap: 20px, Flow: Horizontal
  /// - Background: #001834
  /// - Shadows: Blur 1.63 (#7A79B6), Blur 22.85 (#7A79B6)
  /// - Left Column: CHAPTER pill, Title (e.g. FLORA GROVE), Status (✔ CHAPTER UNLOCKED)
  /// - Right Column: 3 Gold Stars (★ ★ ★), Level Range (LV 21 - 40)
  /// - Positioned next to the path (Left: 168px in Figma frame) avoiding node overlap
  Widget _buildChapterGate({
    required BuildContext context,
    required int gateIndex,
    required double gateCenterY,
    required double screenWidth,
    required double mapHeight,
    required int unlockedLevels,
  }) {
    final LevelChapter targetChapter = kLevelChapters[gateIndex + 1];
    final int requiredLevel = targetChapter.startLevel;
    final bool isUnlocked = unlockedLevels >= requiredLevel;

    final double cardWidth = math.min(212.0, screenWidth - 36.0);
    const double cardHeight = 78.0;

    // Alternate Left-Right vice versa across chapters
    // gateIndex 0 (Chapter 2): Right (matching Figma game level screen)
    // gateIndex 1 (Chapter 3): Left
    // gateIndex 2 (Chapter 4): Right
    // gateIndex 3 (Chapter 5): Left
    // 16.0px margin guarantees cards never touch the boundary of the screen
    final bool placeOnRight = (gateIndex % 2 == 0);
    final double cardLeft = placeOnRight
        ? (screenWidth - cardWidth - 16.0)
        : 16.0;

    return Positioned(
      left: cardLeft,
      top: gateCenterY - (cardHeight / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.playClickSound();
          HapticFeedback.lightImpact();
          _showChapterInfoDialog(targetChapter, isUnlocked, unlockedLevels);
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double pulseValue = _pulseController.value;
            // Subtle floating levitation offset
            final double hoverOffsetY =
                math.sin((pulseValue * 2 * math.pi) + (gateIndex * 1.5)) * 2.5;

            return Transform.translate(
              offset: Offset(0, hoverOffsetY),
              child: child,
            );
          },
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFC800),
                  Color(0xFF814D00),
                  Color(0xFF6B4000),
                  Color(0xFF814D00),
                  Color(0xFFFFC800),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                // Figma Drop shadow 1: Blur: 1.63, Color: #7A79B6
                BoxShadow(
                  color: const Color(0xFF7A79B6).withValues(alpha: 0.55),
                  blurRadius: 1.63,
                  spreadRadius: 0,
                ),
                // Figma Drop shadow 2: Blur: 22.85, Color: #7A79B6
                BoxShadow(
                  color: const Color(0xFF7A79B6).withValues(alpha: 0.38),
                  blurRadius: 22.85,
                  spreadRadius: 0,
                ),
                // Deep dark contrast shadow for map depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.0), // Figma 1px border
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Figma padding: 10px
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF001834), // Figma Fill: #001834
                borderRadius: BorderRadius.circular(9),
                image: const DecorationImage(
                  image: AssetImage('assets/leaderboard_icons/back_design.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  colorFilter: ColorFilter.mode(
                    Color(0xFF001834),
                    BlendMode.modulate,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // LEFT COLUMN: CHAPTER PILL + TITLE + STATUS
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Chapter Pill (e.g. CHAPTER 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001834),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFC800),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'CHAPTER ${targetChapter.number}',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // 2. Chapter Title (e.g. SUNBURST MEADOW) with FittedBox protection
                          SizedBox(
                            height: 18,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                targetChapter.title.toUpperCase(),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // 3. Status Badge with FittedBox protection
                          SizedBox(
                            height: 14,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUnlocked
                                        ? Icons.check_circle_rounded
                                        : Icons.lock_rounded,
                                    color: isUnlocked
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFFB800),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUnlocked
                                        ? 'CHAPTER UNLOCKED'
                                        : 'UNLOCK AT LV $requiredLevel',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      color: isUnlocked
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFFB800),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // RIGHT COLUMN: 3 STARS + LEVEL RANGE (e.g. ★ ★ ★ and LV 21 - 40)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 3 Stars in a row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int s = 0; s < 3; s++) ...[
                              Icon(
                                Icons.star_rounded,
                                color: isUnlocked
                                    ? const Color(0xFFFFC800)
                                    : Colors.white24,
                                size: 15,
                              ),
                              if (s < 2) const SizedBox(width: 2),
                            ],
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Level range (e.g. LV 21 - 40)
                        Text(
                          'LV ${targetChapter.startLevel} - ${targetChapter.endLevel}',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.4,
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

  /// Moving / Hovering Avatar Indicator stationed at current active unlocked level (Candy Crush Saga Style)
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

          // Dynamic cartoon jump physics: tilt forward in flight direction & squash on hop
          final double flightTilt =
              (currPos.dx >= prevPos.dx ? 1.0 : -1.0) *
              math.sin(t * math.pi) *
              0.16;
          final double jumpSquash = 1.0 + (math.sin(t * math.pi * 2) * 0.12);

          return Positioned(
            left: pathPos.dx - 27,
            top: pathPos.dy - 76,
            child: Transform.rotate(
              angle: flightTilt,
              child: Transform.scale(
                scale: jumpSquash,
                child: _buildAvatarBadge(isMoving: true),
              ),
            ),
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
        final double pulseVal = _pulseController.value;
        final double bobOffset = _avatarEntranceController.isCompleted
            ? math.sin(pulseVal * 2 * math.pi) * 4.5
            : 0.0;
        final double breatheX =
            1.0 + (math.sin(pulseVal * 2 * math.pi) * 0.04);
        final double breatheY =
            1.0 - (math.sin(pulseVal * 2 * math.pi) * 0.04);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Under-avatar glowing spotlight beacon directly on current level node
            Positioned(
              left: currPos.dx - 24,
              top: currPos.dy - 6,
              child: IgnorePointer(
                child: Container(
                  width: 48,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(
                          alpha:
                              0.45 + (0.35 * math.sin(pulseVal * math.pi)),
                        ),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Player Avatar with Crown, Specular Gloss, and "YOU" Banner
            Positioned(
              left: currPos.dx - 27,
              top: currPos.dy - 76 + entranceOffset + bobOffset,
              child: Transform.scale(
                scaleX: breatheX,
                scaleY: breatheY,
                child: _buildAvatarBadge(isMoving: false),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Candy Crush Saga style Player Character Marker with 3D Medallion, Crown & "YOU" Ribbon Banner
  Widget _buildAvatarBadge({bool isMoving = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Floating Golden Crown
        Container(
          margin: const EdgeInsets.only(bottom: 1),
          child: const Text('👑', style: TextStyle(fontSize: 14, height: 1.0)),
        ),

        // 2. Shiny 3D Avatar Medallion with Flower Icon & Specular Reflection
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFE082),
                Color(0xFFFFB300),
                Color(0xFFF57C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.65),
                blurRadius: 16,
                spreadRadius: 3,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vibrant Sky Blue Inner Disc
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/levels_elements/flower.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // Glossy Curvature Specular Highlight
              Positioned(
                top: 3,
                left: 8,
                right: 8,
                height: 14,
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
            ],
          ),
        ),

        const SizedBox(height: 3),

        // 3. Candy Crush Style "YOU" Marker Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF2A6D), Color(0xFFC2185B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD54F),
                size: 10,
              ),
              const SizedBox(width: 3),
              Text(
                'YOU',
                style: GoogleFonts.chakraPetch(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1.1,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Interactive Animated Scenery Element (gate.png, house.png, tree.png, flower.png)
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

    return CandyCrushAnimatedSceneryElement(
      element: element,
      position: pos,
      shimmerAnimation: _shimmerAnimation,
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

/// Candy Crush style lively animated scenery element:
/// - Floating levitation hover bobbing
/// - Organic squash & stretch breathing
/// - Gentle enchanted breeze pendulum sway
/// - Element-specific pulsing magical aura halo
/// - Twinkling magical firefly sparkles (✦)
/// - Juicy elastic cartoon bounce upon tap
class CandyCrushAnimatedSceneryElement extends StatefulWidget {
  final LevelMapSceneryElement element;
  final Offset position;
  final Animation<double> shimmerAnimation;

  const CandyCrushAnimatedSceneryElement({
    super.key,
    required this.element,
    required this.position,
    required this.shimmerAnimation,
  });

  @override
  State<CandyCrushAnimatedSceneryElement> createState() =>
      _CandyCrushAnimatedSceneryElementState();
}

class _CandyCrushAnimatedSceneryElementState
    extends State<CandyCrushAnimatedSceneryElement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapSpringScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Candy Crush elastic spring pop: quick squash -> overshoot -> bounce settle
    _tapSpringScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    AudioService.instance.playClickSound();
    _tapController.forward(from: 0.0);
  }

  Color _getAuraColor() {
    final asset = widget.element.asset;
    if (asset.contains('tree')) {
      return const Color(0xFF00E5FF); // Luminescent cyan
    } else if (asset.contains('house')) {
      return const Color(0xFFFFB300); // Warm fairy lantern amber
    } else if (asset.contains('flower')) {
      return const Color(0xFFFF4081); // Vibrant floral magenta
    } else {
      return const Color(0xFF69F0AE); // Mystic emerald ivy
    }
  }

  @override
  Widget build(BuildContext context) {
    final auraColor = _getAuraColor();
    // Unique phase offset per element so elements don't bob in lockstep
    final double phase = widget.element.levelAnchor * 1.85;

    return Positioned(
      left: widget.position.dx - (widget.element.width / 2) - 12,
      top: widget.position.dy - (widget.element.height / 2) - 12,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.shimmerAnimation, _tapController]),
        builder: (context, child) {
          final double t = widget.shimmerAnimation.value;
          final double angle = (t * 2 * math.pi) + phase;

          // 1. Idle Floating Bob (±4.5 px)
          final double bobY = math.sin(angle) * 4.5;

          // 2. Squash & Stretch Breathing
          final double breatheScaleX = 1.0 + (math.sin(angle) * 0.035);
          final double breatheScaleY = 1.0 - (math.sin(angle) * 0.035);

          // 3. Pendulum Sway Tilt (±2.5 degrees)
          final double swayAngle = math.sin(angle * 0.5) * 0.045;

          // 4. Tap pop multiplier
          final double tapScale = _tapController.isAnimating
              ? _tapSpringScale.value
              : 1.0;

          // 5. Breathing aura halo opacity
          final double auraPulse = 0.35 + (0.25 * ((math.sin(angle) + 1) / 2));

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: SizedBox(
              width: widget.element.width + 24,
              height: widget.element.height + 24,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // A. Magical Breathing Halo Aura
                  Transform.translate(
                    offset: Offset(0, bobY),
                    child: Container(
                      width: widget.element.width * 0.85,
                      height: widget.element.height * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: auraColor.withValues(
                              alpha: auraPulse *
                                  (_tapController.isAnimating ? 1.6 : 1.0),
                            ),
                            blurRadius: 22.0 +
                                (_tapController.isAnimating ? 14.0 : 0.0),
                            spreadRadius: 4.0 +
                                (_tapController.isAnimating ? 6.0 : 0.0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // B. Main Element Graphic with Squash, Stretch, Tilt, and Tap Elasticity
                  Transform.translate(
                    offset: Offset(0, bobY),
                    child: Transform.rotate(
                      angle: swayAngle,
                      child: Transform.scale(
                        scaleX: breatheScaleX * tapScale,
                        scaleY: breatheScaleY * tapScale,
                        child: Image.asset(
                          widget.element.asset,
                          width: widget.element.width,
                          height: widget.element.height,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                  // C. Twinkling Magic Sparkle ✦ (Top-Right)
                  Positioned(
                    top: 2 + (bobY * 0.5),
                    right: 4,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: t * 2 * math.pi,
                        child: Transform.scale(
                          scale: (0.5 +
                                  (0.5 *
                                      ((math.sin(angle + 1.2) + 1) / 2))) *
                              tapScale,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Color.lerp(
                              auraColor,
                              Colors.white,
                              0.65,
                            )!.withValues(
                              alpha: 0.45 +
                                  (0.55 * ((math.sin(angle + 1.2) + 1) / 2)),
                            ),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // D. Twinkling Magic Sparkle ✦ (Bottom-Left)
                  Positioned(
                    bottom: 4 + (bobY * 0.5),
                    left: 2,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -t * 2 * math.pi,
                        child: Transform.scale(
                          scale: (0.45 +
                                  (0.45 *
                                      ((math.sin(angle + 3.14) + 1) / 2))) *
                              tapScale,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Color.lerp(
                              auraColor,
                              Colors.white,
                              0.75,
                            )!.withValues(
                              alpha: 0.4 +
                                  (0.5 * ((math.sin(angle + 3.14) + 1) / 2)),
                            ),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

/// Animated floating firefly particles drifting upward across the magical level map (Candy Crush / Gardenscapes aesthetic)
class AmbientFirefliesPainter extends CustomPainter {
  final double progress;
  static const int _particleCount = 22;

  AmbientFirefliesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final Paint glowPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _particleCount; i++) {
      // Deterministic pseudo-random distribution per particle
      final double seed = (i * 97.13) % 1.0;
      final double speed = 0.35 + (((i * 37) % 5) * 0.12);
      final double currentT = (progress * speed + seed) % 1.0;

      // Vertical drift upward
      final double y = size.height * (1.0 - currentT);

      // Horizontal organic sine sway
      final double swayAmplitude = 18.0 + ((i % 4) * 7.0);
      final double baseX = size.width * ((seed * 1.55) % 1.0);
      final double x = baseX +
          math.sin((currentT * 4 * math.pi) + (i * 1.5)) * swayAmplitude;

      // Twinkling opacity
      final double twinkle =
          (math.sin((currentT * 6 * math.pi) + (i * 2.0)) + 1.0) / 2.0;
      final double alpha = (0.20 + 0.70 * twinkle).clamp(0.0, 1.0);

      // Particle size
      final double radius = 1.8 + ((i % 3) * 1.1);

      // Themed firefly color: golden fairy light / soft emerald / mystic cyan
      final Color color = (i % 3 == 0)
          ? const Color(0xFFFFF59D)
          : (i % 3 == 1)
              ? const Color(0xFF69F0AE)
              : const Color(0xFF80D8FF);

      // Outer soft glow
      glowPaint.color = color.withValues(alpha: alpha * 0.45);
      canvas.drawCircle(Offset(x, y), radius * 2.4, glowPaint);

      // Bright inner core
      glowPaint.color = Colors.white.withValues(alpha: alpha * 0.9);
      canvas.drawCircle(Offset(x, y), radius * 0.8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientFirefliesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Ambient drifting stylized clouds layer providing authentic Candy Crush Saga depth & atmosphere
class AmbientCloudsPainter extends CustomPainter {
  final double progress;

  AmbientCloudsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // 4 Drifting cloud layers at different altitudes, speeds, scales, and opacities
    const List<_CloudConfig> configs = [
      _CloudConfig(
        baseYFraction: 0.12,
        speed: 0.65,
        scale: 1.3,
        opacity: 0.13,
        xOffset: 0.08,
      ),
      _CloudConfig(
        baseYFraction: 0.38,
        speed: 1.0,
        scale: 0.95,
        opacity: 0.15,
        xOffset: 0.62,
      ),
      _CloudConfig(
        baseYFraction: 0.64,
        speed: 0.8,
        scale: 1.2,
        opacity: 0.14,
        xOffset: 0.32,
      ),
      _CloudConfig(
        baseYFraction: 0.86,
        speed: 1.15,
        scale: 1.05,
        opacity: 0.15,
        xOffset: 0.82,
      ),
    ];

    for (final cfg in configs) {
      final double totalTravel = size.width + (260 * cfg.scale);
      final double x =
          ((progress * cfg.speed + cfg.xOffset) % 1.0) * totalTravel -
          (130 * cfg.scale);
      final double y = size.height * cfg.baseYFraction;
      _drawFluffyCloud(canvas, Offset(x, y), cfg.scale, cfg.opacity);
    }
  }

  void _drawFluffyCloud(
    Canvas canvas,
    Offset center,
    double scale,
    double opacity,
  ) {
    final Paint cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Clustered rounded puffs creating a classic soft cartoon cloud shape
    canvas.drawCircle(
      Offset(center.dx - 36 * scale, center.dy + 4 * scale),
      24 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 10 * scale),
      34 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 34 * scale, center.dy + 2 * scale),
      26 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - 14 * scale, center.dy + 12 * scale),
      22 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 16 * scale, center.dy + 12 * scale),
      22 * scale,
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AmbientCloudsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CloudConfig {
  final double baseYFraction;
  final double speed;
  final double scale;
  final double opacity;
  final double xOffset;

  const _CloudConfig({
    required this.baseYFraction,
    required this.speed,
    required this.scale,
    required this.opacity,
    required this.xOffset,
  });
}
