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
  String _activeThemeBg = 'assets/decorate/1.png';

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

    final currentStage = gardenStages.firstWhere(
      (g) => g['level'] == currentGardenLvl,
      orElse: () => gardenStages[3], // Default: Garden House
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05001C),
      body: Stack(
        children: [
          // Background Garden Image (e.g. assets/decorate/1.png)
          Positioned.fill(
            child: Image.asset(
              _activeThemeBg,
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
                    _buildOverviewContent(context, flowers),
                  ] else ...[
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildTabContent(flowers, currentGardenLvl),
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
  Widget _buildTabContent(int flowers, int currentGardenLvl) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewContent(context, flowers);
      case 1:
        return _buildDecorateContent(flowers, currentGardenLvl);
      case 2:
        return _buildThemesContent();
      case 3:
        return _buildStatsContent(flowers, currentGardenLvl);
      default:
        return _buildOverviewContent(context, flowers);
    }
  }

  // --- TAB 0: OVERVIEW CONTENT ---
  Widget _buildOverviewContent(BuildContext context, int flowers) {
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
                  backgroundAsset: _activeThemeBg,
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
  Widget _buildThemesContent() {
    final List<Map<String, String>> themes = [
      {'name': 'Night Garden', 'asset': 'assets/decorate/1.png'},
      {'name': 'Sprout Sanctuary', 'asset': 'assets/decorate/2.png'},
      {'name': 'Tree Haven', 'asset': 'assets/decorate/3.png'},
      {'name': 'Cottage Paradise', 'asset': 'assets/decorate/4.png'},
      {'name': 'Sparkling Fountain', 'asset': 'assets/decorate/5.png'},
      {'name': 'Harmonious Eden', 'asset': 'assets/decorate/6.png'},
    ];

    return Column(
      key: const ValueKey('ThemesTab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'GARDEN THEMES',
            style: GoogleFonts.chakraPetch(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFC800),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = _activeThemeBg == theme['asset'];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AudioService.instance.playClickSound();
                  setState(() {
                    _activeThemeBg = theme['asset']!;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFC800) : const Color(0xFF103975),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    image: DecorationImage(
                      image: AssetImage(theme['asset']!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: Color(0x66FFC800),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              theme['name']!,
                              style: GoogleFonts.chakraPetch(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFFFC800),
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
