import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/garden/views/garden_fullscreen_view.dart';
import 'package:block_bloom/ui/features/garden/widgets/flower_counter_badge.dart';
import 'package:block_bloom/ui/features/garden/widgets/garden_nav_bar.dart';
import 'package:block_bloom/ui/features/garden/widgets/garden_shield_badge.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/domain/models/user_progress.dart';

/// Screen 1: My Garden Main View Screen
/// Contains Top Bar (Back button, MY GARDEN title, FlowerCounterBadge using sample.png),
/// Center GardenShieldBadge (using my_garden_shield.png with GARDEN LEVEL & number),
/// Dynamic tab content (OVERVIEW, DECORATE, THEMES, STATS),
/// VIEW GARDEN FULLSCREEN button (navigates to Screen 2: GardenFullscreenView),
/// and custom bottom GardenNavBar (75x68px tabs matching exact Figma specs).
class GardenView extends ConsumerStatefulWidget {
  const GardenView({super.key});

  @override
  ConsumerState<GardenView> createState() => _GardenViewState();
}

class _GardenViewState extends ConsumerState<GardenView> {
  int _selectedTabIndex = 0; // Default: 0 = OVERVIEW
  String _activeThemeBg = 'assets/decorate/6.png';

  static const List<Map<String, dynamic>> gardenStages = [
    {
      'level': 1,
      'name': 'Empty Garden',
      'iconAsset': 'assets/decorate_icons/leaf.png',
      'cost': 0,
      'image': 'assets/decorate/1.png',
      'description': 'A small fertile plot of land ready for planting.',
      'unlockCondition': '',
    },
    {
      'level': 2,
      'name': 'Garden House',
      'iconAsset': 'assets/decorate_icons/garden.png',
      'cost': 200,
      'image': 'assets/decorate/2.png',
      'description': 'Your garden grows with every flower you collect.',
      'unlockCondition': '',
    },
    {
      'level': 3,
      'name': 'Fountain',
      'iconAsset': 'assets/decorate_icons/fountain.png',
      'cost': 400,
      'image': 'assets/decorate/3.png',
      'description': 'A majestic stone fountain sparkling in the sunlight.',
      'unlockCondition': '',
    },
    {
      'level': 4,
      'name': 'Small Garden',
      'iconAsset': 'assets/decorate_icons/small_garden.png',
      'cost': 600,
      'image': 'assets/decorate/4.png',
      'description': 'Fresh tulips and colorful sprouts blooming brightly.',
      'unlockCondition': '',
    },
    {
      'level': 5,
      'name': 'Trees',
      'iconAsset': 'assets/decorate_icons/trees.png',
      'cost': 800,
      'image': 'assets/decorate/5.png',
      'description': 'Lush trees providing shade and peaceful natural vibes.',
      'unlockCondition': 'Available after unlocking Garden House.',
    },
    {
      'level': 6,
      'name': 'Complete Garden',
      'iconAsset': 'assets/decorate_icons/rainbow.png',
      'cost': 1000,
      'image': 'assets/decorate/6.png',
      'description': 'A magical paradise glowing with complete harmony.',
      'unlockCondition': 'Available after unlocking Fountain.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final progress = homeState.progress;
    final flowers = progress?.flowers ?? 1200;
    final currentGardenLvl = progress?.gardenLevel ?? 1;
    final activeThemeAsset = (progress != null && progress.activeTheme.isNotEmpty)
        ? progress.activeTheme
        : _activeThemeBg;

    final currentStage = gardenStages.firstWhere(
      (g) => g['level'] == currentGardenLvl,
      orElse: () => gardenStages[3], // Default: Garden House
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05001C),
      body: Stack(
        children: [
          // Background Garden Image (Rendered on Overview tab 0; Themes page has solid dark navy background matching Figma design)
          if (_selectedTabIndex == 0)
            Positioned.fill(
              child: Image.asset(
                activeThemeAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/splash_img.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (c2, e2, s2) => Container(color: const Color(0xFF0F172A)),
                ),
              ),
            ),

          // Subtle Vignette Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x9905001C),
                    Color(0x1A05001C),
                    Color(0xDD05001C),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // 1. TOP HEADER BAR: Back Arrow + MY GARDEN + Flower Counter Badge
                  _buildTopHeaderBar(context, flowers),

                  const SizedBox(height: 14),

                  // 2. CENTER HERO SHIELD BADGE (Shown on Overview Tab) & TAB CONTENT
                  if (_selectedTabIndex == 0) ...[
                    GardenShieldBadge(
                      level: currentGardenLvl,
                      stageName: currentStage['name'] as String,
                      description: currentStage['description'] as String,
                    ),
                    const Spacer(),
                    _buildOverviewContent(context, flowers, activeThemeAsset),
                  ] else ...[
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildTabContent(flowers, currentGardenLvl, progress, activeThemeAsset),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // 3. BOTTOM NAV BAR (OVERVIEW | DECORATE | THEMES | STATS)
                  GardenNavBar(
                    selectedIndex: _selectedTabIndex,
                    onItemSelected: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. TOP HEADER BAR ---
  Widget _buildTopHeaderBar(BuildContext context, int flowers) {
    final String titleText;
    switch (_selectedTabIndex) {
      case 1:
        titleText = 'DECORATE';
        break;
      case 2:
        titleText = 'THEMES';
        break;
      case 3:
        titleText = 'STATS';
        break;
      default:
        titleText = 'MY GARDEN';
    }

    return Row(
      children: [
        // Left: Back Arrow Vector (Layout: 20px x 20px, Gradient #FFFFFF to #E9CC70)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            AudioService.instance.playClickSound();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: SizedBox(
            width: 20,
            height: 20,
            child: ShaderMask(
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
          ),
        ),

        const SizedBox(width: 10),

        // Center: Dynamic Header Title (Chakra Petch 22px 600 SemiBold, #FFFFFF to #E9CC70)
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            titleText,
            style: GoogleFonts.chakraPetch(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
              letterSpacing: 0.0,
            ),
          ),
        ),

        const Spacer(),

        // Right: Flower Counter Badge using sample.png background
        FlowerCounterBadge(count: flowers),
      ],
    );
  }

  // --- 3. DYNAMIC TAB CONTENT SWITCHER ---
  Widget _buildTabContent(int flowers, int currentGardenLvl, UserProgress? progress, String activeThemeAsset) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewContent(context, flowers, activeThemeAsset);
      case 1:
        return _buildDecorateContent(flowers, currentGardenLvl);
      case 2:
        return _buildThemesContent(flowers, currentGardenLvl, progress, activeThemeAsset);
      case 3:
        return _buildStatsContent(flowers, currentGardenLvl);
      default:
        return _buildOverviewContent(context, flowers, activeThemeAsset);
    }
  }

  // --- TAB 0: OVERVIEW CONTENT ---
  Widget _buildOverviewContent(BuildContext context, int flowers, String activeThemeAsset) {
    return Column(
      key: const ValueKey('OverviewTab'),
      mainAxisSize: MainAxisSize.min,
      children: [

        // Next Level Progress Card (Screenshot 4)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF001126),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFC800),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: NEXT LEVEL 5 - FOUNTAIN
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'NEXT LEVEL 5 - FOUNTAIN',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Progress Bar Row: Flower Icon + Progress Bar + Info (i) Icon
              Row(
                children: [
                  // Flower Icon
                  Image.asset(
                    'assets/game_flower.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => const Text('🌸', style: TextStyle(fontSize: 22)),
                  ),

                  const SizedBox(width: 10),

                  // Gradient Progress Bar
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF001D3D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFC800).withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (400 / 600).clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE9C46A), Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          '400/600',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Info Icon Button
                  GestureDetector(
                    onTap: () {
                      _showInfoDialog(context);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2096E7),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'i',
                          style: TextStyle(
                            color: Color(0xFF2096E7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // VIEW GARDEN FULLSCREEN Button (Navigates to Screen 2: GardenFullscreenView)
        GreenGameButton(
          text: 'VIEW GARDEN FULLSCREEN',
          width: double.infinity,
          height: 48,
          fontSize: 15,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GardenFullscreenView(
                  backgroundAsset: activeThemeAsset,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Group 178 Level Badge Specs:
  /// 35px x 35px Circle with 1.05px 5-stop Gold Gradient border (#FFC800 -> #814D00 -> #6B4000 -> #814D00 -> #FFC800)
  Widget _buildLevelCircleBadge(int lvl) {
    return Container(
      width: 35,
      height: 35,
      padding: const EdgeInsets.all(1.05),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFC800),
            Color(0xFF814D00),
            Color(0xFF6B4000),
            Color(0xFF814D00),
            Color(0xFFFFC800),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF001126),
        ),
        child: Center(
          child: Text(
            '$lvl',
            style: GoogleFonts.chakraPetch(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFC800),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: DECORATE CONTENT ---
  Widget _buildDecorateContent(int flowers, int currentGardenLvl) {
    return Column(
      key: const ValueKey('DecorateTab'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          child: Text(
            'Grow your garden and unlock new areas!',
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: gardenStages.length,
            itemBuilder: (context, index) {
              final stage = gardenStages[index];
              final lvl = stage['level'] as int;
              final isUnlocked = lvl <= currentGardenLvl;
              final isNext = lvl == currentGardenLvl + 1;
              final cost = stage['cost'] as int;
              final unlockCond = stage['unlockCondition'] as String? ?? '';

              // Active card gets 1.5px gold gradient border outline
              final BoxBorder cardBorder;
              if (isNext) {
                cardBorder = const GradientBorder(
                  width: 1.5,
                  gradient: LinearGradient(
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
                );
              } else {
                cardBorder = Border.all(
                  color: isUnlocked ? const Color(0xFF103975) : const Color(0xFF0D2545),
                  width: 1.0,
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF001126),
                  borderRadius: BorderRadius.circular(14),
                  border: cardBorder,
                  boxShadow: isNext
                      ? const [
                          BoxShadow(
                            color: Color(0x40FFC800),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // 1. Group 178 Level Badge (35x35px gold gradient border circle)
                    _buildLevelCircleBadge(lvl),

                    const SizedBox(width: 12),

                    // 2. Icon from assets/decorate_icons/
                    Image.asset(
                      stage['iconAsset'] as String,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => const Icon(
                        Icons.nature_rounded,
                        size: 32,
                        color: Color(0xFFFFC800),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 3. Title & Subtitle / Progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['name'] as String,
                            style: GoogleFonts.chakraPetch(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isUnlocked
                                  ? Colors.white
                                  : (isNext ? const Color(0xFFFFC800) : Colors.white),
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(height: 4),
                            // Compact Progress bar inside active item (Pink flower icon + purple gradient progress)
                            Row(
                              children: [
                                Image.asset(
                                  'assets/small_flower.png',
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Text('🌸', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF050B20),
                                          borderRadius: BorderRadius.circular(6.5),
                                          border: Border.all(
                                            color: const Color(0xFFFFC800).withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: (flowers / (cost > 0 ? cost : 1)).clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          height: 13,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE9C46A), Color(0xFF8B5CF6)],
                                            ),
                                            borderRadius: BorderRadius.circular(6.5),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$flowers/$cost',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else if (!isUnlocked && unlockCond.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              unlockCond,
                              style: GoogleFonts.chakraPetch(
                                fontSize: 10,
                                color: const Color(0xFF809BCE),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 4. Status Action Element: Checkmark (Unlocked) / UNLOCK Button (Active) / Lock Icon (Locked)
                    if (isUnlocked)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF52A421), Color(0xFF2E6510)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      )
                    else if (isNext)
                      GreenGameButton(
                        text: 'UNLOCK',
                        width: 75,
                        height: 32,
                        fontSize: 11,
                        onPressed: flowers >= cost
                            ? () async {
                                HapticFeedback.heavyImpact();
                                final repo = ref.read(progressRepositoryProvider);
                                final success = await repo.upgradeGarden(cost);
                                if (success) {
                                  ref.read(homeViewModelProvider.notifier).loadProgress();
                                }
                              }
                            : null,
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A2240),
                          border: Border.all(
                            color: const Color(0xFF1A4575),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: THEMES CONTENT ---
  Widget _buildThemesContent(int flowers, int currentGardenLvl, UserProgress? progress, String activeThemeAsset) {
    final unlockedThemes = progress?.unlockedThemes ?? ['classic'];
    final activeTheme = (progress != null && progress.activeTheme.isNotEmpty)
        ? progress.activeTheme
        : activeThemeAsset;

    final List<Map<String, dynamic>> themesData = [
      {
        'id': 'classic',
        'name': 'Classic Garden',
        'asset': 'assets/decorate/6.png',
        'alignment': const Alignment(-0.95, -0.35),
        'subtitle': 'Lvl $currentGardenLvl/Lvl 6',
        'cost': 0,
      },
      {
        'id': 'space',
        'name': 'Space Garden',
        'asset': 'assets/themes/1.png',
        'alignment': const Alignment(-0.95, -0.35),
        'subtitle': 'Unlocks after completion of classic garden',
        'cost': 1000,
      },
      {
        'id': 'candy',
        'name': 'Candy Garden',
        'asset': 'assets/themes/2.png',
        'alignment': const Alignment(-0.95, -0.35),
        'subtitle': 'Available after unlocking Space Garden.',
        'cost': 2000,
      },
      {
        'id': 'ocean',
        'name': 'Ocean Garden',
        'asset': 'assets/themes/3.png',
        'alignment': const Alignment(-0.95, -0.35),
        'subtitle': 'Available after unlocking Candy Garden.',
        'cost': 3000,
      },
    ];

    return Column(
      key: const ValueKey('ThemesTab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtitle Text: "Change the look and feel of your garden."
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 12),
          child: Text(
            'Change the look and feel of your garden.',
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // Scrollable List of Theme Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: themesData.length,
            itemBuilder: (context, index) {
              final theme = themesData[index];
              final themeId = theme['id'] as String;
              final themeAsset = theme['asset'] as String;
              final themeName = theme['name'] as String;
              final subtitle = theme['subtitle'] as String;
              final cost = theme['cost'] as int;
              final alignment = (theme['alignment'] as Alignment?) ?? const Alignment(-0.95, -0.35);

              final isUnlocked = unlockedThemes.contains(themeId) || themeId == 'classic';
              final isActive = activeTheme == themeAsset;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF001126),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? const Color(0xFFFFC800) : const Color(0xFFFFC800).withValues(alpha: 0.7),
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left: Theme Image Thumbnail focusing on House Side View (Zoomed 1.25x)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 145,
                        height: 98,
                        color: const Color(0xFF0F172A),
                        child: Transform.scale(
                          scale: 1.25,
                          alignment: alignment,
                          child: Image.asset(
                            themeAsset,
                            fit: BoxFit.cover,
                            alignment: alignment,
                            width: 145,
                            height: 98,
                            errorBuilder: (ctx, err, st) => Image.asset(
                              'assets/splash_img.png',
                              fit: BoxFit.cover,
                              alignment: alignment,
                              width: 145,
                              height: 98,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title with Linear Gradient (#FFFFFF -> #E9CC70) - Exact Figma 20px spec
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              themeName,
                              style: GoogleFonts.chakraPetch(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle / Requirement / Progress (12px clean text)
                          if (themeId == 'classic') ...[
                            // Progress pill bar: Lvl 4/Lvl 6
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE9C46A), Color(0xFF8B5CF6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Text(
                                subtitle,
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 12,
                                      color: const Color(0xFFB0C4DE),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Action Element: ACTIVE Badge (Frame 140) / USE THEME / UNLOCK FOR 🌸 Cost (Frame 152)
                          if (isActive) ...[
                            // ACTIVE BADGE (Frame 140 Specs: green gradient fill, 1px gradient border)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF94C745), Color(0xFF1A3C0E)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFDBF19A),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFDBF19A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ACTIVE',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isUnlocked) ...[
                            // USE THEME Button
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                AudioService.instance.playClickSound();
                                setState(() {
                                  _activeThemeBg = themeAsset;
                                });
                                final repo = ref.read(progressRepositoryProvider);
                                await repo.setActiveTheme(themeAsset);
                                ref.read(homeViewModelProvider.notifier).loadProgress();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF94C745), Color(0xFF1A3C0E)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFDBF19A),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'USE THEME',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // UNLOCK FOR 🌸 COST Button (Frame 152 Specs: 142.89px Hug x 24px Hug)
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.heavyImpact();
                                final repo = ref.read(progressRepositoryProvider);
                                if (flowers >= cost) {
                                  final success = await repo.unlockTheme(themeId, cost, themeAsset);
                                  if (success) {
                                    setState(() {
                                      _activeThemeBg = themeAsset;
                                    });
                                    ref.read(homeViewModelProvider.notifier).loadProgress();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$themeName unlocked and activated!',
                                            style: GoogleFonts.chakraPetch(color: Colors.white),
                                          ),
                                          backgroundColor: const Color(0xFF52A421),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  AudioService.instance.playClickSound();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Need ${cost - flowers} more 🌸 to unlock $themeName!',
                                          style: GoogleFonts.chakraPetch(color: Colors.white),
                                        ),
                                        backgroundColor: const Color(0xFFD32F2F),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF94C745), Color(0xFF1A3C0E)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFDBF19A),
                                    width: 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'UNLOCK FOR ',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/small_flower.png',
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Text('🌸', style: TextStyle(fontSize: 10)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$cost',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFFC800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: STATS CONTENT ---
  Widget _buildStatsContent(int flowers, int currentGardenLvl) {
    final List<Map<String, dynamic>> statCards = [
      {
        'title': 'HIGHEST SCORE',
        'value': '24,580',
        'icon': 'assets/stats/score.png',
        'fallbackIcon': Icons.emoji_events_rounded,
      },
      {
        'title': 'GAMES PLAYED',
        'value': '128',
        'icon': 'assets/stats/game_played.png',
        'fallbackIcon': Icons.sports_esports_rounded,
      },
      {
        'title': 'BEST COMBO',
        'value': 'X8',
        'icon': 'assets/stats/star.png',
        'fallbackIcon': Icons.star_rounded,
      },
      {
        'title': 'FLOWERS COLLECTED',
        'value': flowers > 0 ? '$flowers' : '2,450',
        'icon': 'assets/stats/flower.png',
        'fallbackIcon': Icons.local_florist_rounded,
      },
      {
        'title': 'LINES CLEARED',
        'value': '1,820',
        'icon': 'assets/stats/lines.png',
        'fallbackIcon': Icons.grid_view_rounded,
      },
      {
        'title': 'AVG SCORE',
        'value': '12,340',
        'icon': 'assets/stats/avg.png',
        'fallbackIcon': Icons.trending_up_rounded,
      },
    ];

    return GridView.builder(
      key: const ValueKey('StatsTab'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) {
        final card = statCards[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF001126),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFC800),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stat Icon from assets/stats/
              SizedBox(
                width: 52,
                height: 52,
                child: Image.asset(
                  card['icon'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => Icon(
                    card['fallbackIcon'] as IconData,
                    size: 40,
                    color: const Color(0xFFFFC800),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title Label
              Text(
                card['title'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.chakraPetch(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB0C4DE),
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 4),

              // Stat Value with LinearGradient #FFFFFF to #E9CC70
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  card['value'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001126),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFC800), width: 1.5),
        ),
        title: Text(
          'GARDEN PROGRESS',
          style: GoogleFonts.chakraPetch(
            color: const Color(0xFFFFC800),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Collect flowers by playing Block Bloom games to unlock higher garden levels and new garden decorations!',
          style: GoogleFonts.chakraPetch(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'GOT IT',
              style: GoogleFonts.chakraPetch(
                color: const Color(0xFF94C745),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
