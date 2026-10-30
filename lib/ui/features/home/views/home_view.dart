import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/features/level_select/views/level_select_view.dart';
import 'package:block_bloom/ui/features/garden/views/garden_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_intro_view.dart';
import 'package:block_bloom/ui/features/settings/views/settings_view.dart';
import 'package:block_bloom/ui/features/profile/views/profile_view.dart';
import 'package:block_bloom/ui/core/widgets/animated_glossy_play_button.dart';
import 'package:block_bloom/ui/core/widgets/glossy_round_game_button.dart';
import 'package:block_bloom/ui/features/home/widgets/compact_top3_leaderboard_card.dart';
import 'package:block_bloom/ui/features/home/widgets/daily_garden_preview_card.dart';
import 'package:block_bloom/ui/features/shop/views/daily_bloom_quests_view.dart';
import 'package:block_bloom/ui/providers.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeViewModelProvider.notifier).loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen Night Garden Background Image with Perfect Fit
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A),
              ),
            ),
          ),

          // 2. Subtle Dark Vignette Gradient Overlay to enhance UI contrast & depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.50),
                  ],
                ),
              ),
            ),
          ),

          // 3. Ambient Floating Petal Particles Background
          const Positioned.fill(child: PetalParticleField()),

          // 4. Main Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Header Row: Settings (Left) & Profile (Right) - Icons Only with Proper Spacing & Indentation
                _buildTopHeaderRow(context),

                // Expanded Center Content (Logo, Subtitle, 4 Main Game Buttons, Footer Links)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double availableHeight = constraints.maxHeight;
                      final bool isVeryCompact = availableHeight < 560;
                      final bool isCompact = availableHeight < 680;

                      final double horizontalPadding = isVeryCompact ? 16.0 : 20.0;
                      final double contentMaxWidth =
                          constraints.maxWidth - (horizontalPadding * 2);
                      final double bottomRowGap = isVeryCompact ? 8.0 : 10.0;
                      final double roundBtnSize =
                          isVeryCompact ? 46.0 : (isCompact ? 50.0 : 52.0);
                      final double playBtnWidth = (contentMaxWidth -
                              (roundBtnSize * 2) -
                              (bottomRowGap * 2) -
                              8.0)
                          .clamp(140.0, 196.0);
                      final double playBtnHeight = playBtnWidth / 2.686;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: availableHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: isVeryCompact ? 4 : 8,
                              ),
                              child: Column(
                                children: [
                                  const Spacer(flex: 2),

                                  // Center Logo (home_icon.png) - Adjusted for optimal proportions
                                  Center(
                                    child: SizedBox(
                                      width: math.min(contentMaxWidth * 0.86, 280.0),
                                      child: Image.asset(
                                        'assets/home_icon.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Text(
                                          'BLOCK BLOOM',
                                          style: TextStyle(
                                            fontFamily: 'BebasNeue',
                                            fontSize: 48,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isVeryCompact ? 6 : 10),

                                  // Subtitle Text
                                  Text(
                                    isVeryCompact
                                        ? 'Bloom your garden, one block at a time.'
                                        : 'Bloom your garden,\none block at a time.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: isVeryCompact ? 13 : 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.92),
                                      height: 1.25,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isVeryCompact ? 8 : 12),

                                  // Compact Top 3 Leaderboard Podium Card (Directly below subtitle)
                                  SizedBox(
                                    width: math.min(contentMaxWidth, 344.0),
                                    child: const CompactTop3LeaderboardCard(),
                                  ),

                                  SizedBox(height: isVeryCompact ? 8 : 10),

                                  // Featured Daily Garden Preview Card (Directly down the Leaderboard section)
                                  SizedBox(
                                    width: math.min(contentMaxWidth, 344.0),
                                    child: DailyGardenPreviewCard(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const DailyGardenIntroView(),
                                          ),
                                        );
                                        ref
                                            .read(homeViewModelProvider.notifier)
                                            .loadProgress();
                                      },
                                    ),
                                  ),

                                  const Spacer(flex: 2),

                                  // Bottom Action Row: Shop (Left), Animated Play (Middle), Garden (Right)
                                  SizedBox(
                                    width: contentMaxWidth,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // 1. Left: Shop Icon (Circular Glossy Green Button with Free Spin Badge)
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              GlossyRoundGameButton.shop(
                                                size: roundBtnSize,
                                                onPressed: () async {
                                                  await showDailyBloomQuests(context);
                                                  ref
                                                      .read(homeViewModelProvider.notifier)
                                                      .loadProgress();
                                                },
                                              ),
                                              if (ref.watch(progressRepositoryProvider).isBoosterWheelFreeSpinAvailable())
                                                Positioned(
                                                  top: -3,
                                                  right: -3,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFF4081),
                                                          Color(0xFFE91E63),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.35),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      'FREE',
                                                      style: GoogleFonts.sniglet(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          SizedBox(width: bottomRowGap),

                                          // 2. Middle: Animated Glossy Play Button (in between shop and garden)
                                          AnimatedGlossyPlayButton(
                                            width: playBtnWidth,
                                            height: playBtnHeight,
                                            onPressed: state.isLoading
                                                ? null
                                                : () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const LevelSelectView(),
                                                      ),
                                                    );
                                                    ref
                                                        .read(homeViewModelProvider.notifier)
                                                        .loadProgress();
                                                  },
                                          ),

                                          SizedBox(width: bottomRowGap),

                                          // 3. Right: Garden Img Icon (Circular Glossy Green Button)
                                          GlossyRoundGameButton.garden(
                                            size: roundBtnSize,
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const GardenView(initialTabIndex: 0), // Main Garden
                                                ),
                                              );
                                              ref
                                                  .read(homeViewModelProvider.notifier)
                                                  .loadProgress();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isVeryCompact ? 6 : 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Action Bar: Settings on Left & Profile on Right (Balanced Corner Layout)
  Widget _buildTopHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings Icon Button (Top-Left) - Exact icon image as set previously in button
          _TopBarIconButton(
            tooltip: 'Settings',
            icon: SvgPicture.asset(
              'assets/settings_icon.svg',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Icon(
                Icons.settings_outlined,
                color: Color(0xFF725726),
                size: 26,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              AudioService.instance.playClickSound();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsView(),
                ),
              );
            },
          ),

          // Profile Icon Button (Top-Right) - Exact icon image as set previously in button
          _TopBarIconButton(
            tooltip: 'Profile',
            icon: SvgPicture.asset(
              'assets/profile.svg',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 26,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              AudioService.instance.playClickSound();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Clean tactile Icon Button displaying the exact icon image as set previously in the button
class _TopBarIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String tooltip;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<_TopBarIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}


class PetalParticleField extends StatefulWidget {
  const PetalParticleField({super.key});

  @override
  State<PetalParticleField> createState() => _PetalParticleFieldState();
}

class _PetalParticleFieldState extends State<PetalParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Petal> _petals = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 15; i++) {
      _petals.add(_Petal(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.05 + _random.nextDouble() * 0.08,
        size: 12 + _random.nextDouble() * 10,
        emoji: ['🌸', '🍃', '🌱', '🌼'][_random.nextInt(4)],
      ));
    }

    _controller.addListener(() {
      setState(() {
        for (final p in _petals) {
          p.y += p.speed * 0.016;
          p.x += math.sin(p.y * 6) * 0.002;
          if (p.y > 1.1) {
            p.y = -0.1;
            p.x = _random.nextDouble();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _petals.map((p) {
            return Positioned(
              left: p.x * constraints.maxWidth,
              top: p.y * constraints.maxHeight,
              child: Opacity(
                opacity: 0.25,
                child: Text(
                  p.emoji,
                  style: TextStyle(fontSize: p.size),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Petal {
  double x;
  double y;
  double speed;
  double size;
  String emoji;

  _Petal({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.emoji,
  });
}
