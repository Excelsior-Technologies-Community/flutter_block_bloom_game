import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';
import 'package:flutter/services.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/features/level_select/views/level_select_view.dart';
import 'package:block_bloom/ui/features/garden/views/garden_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_intro_view.dart';
import 'package:block_bloom/ui/features/leaderboard/views/leaderboard_view.dart';
import 'package:block_bloom/ui/features/settings/views/settings_view.dart';
import 'package:block_bloom/ui/features/profile/views/profile_view.dart';
import 'package:block_bloom/ui/features/terms/views/terms_view.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Night Garden Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A),
              ),
            ),
          ),

          // Ambient Floating Petal Particles Background
          const Positioned.fill(child: PetalParticleField()),

          // Main Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableHeight = constraints.maxHeight;
                final bool isVeryCompact = availableHeight < 620;
                final bool isCompact = availableHeight < 740;

                final double buttonHeight =
                    isVeryCompact ? 44.0 : (isCompact ? 48.0 : 54.0);
                final double buttonGap =
                    isVeryCompact ? 8.0 : (isCompact ? 10.0 : 12.0);
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: isVeryCompact ? 8 : 14,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // Center Logo (home_icon.png)
                            Center(
                              child: SizedBox(
                                width: math.min(size.width * 0.80, 310),
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

                            const Spacer(flex: 3),

                            // Centered Glossy Game Buttons Stack
                            SizedBox(
                              width: math.min(size.width * 0.85, 320),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GlossyGameButton.play(
                                    height: buttonHeight,
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

                                  SizedBox(height: buttonGap),

                                  GlossyGameButton.dailyGarden(
                                    height: buttonHeight,
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

                                  SizedBox(height: buttonGap),

                                  GlossyGameButton.garden(
                                    height: buttonHeight,
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const GardenView(),
                                        ),
                                      );
                                      ref
                                          .read(homeViewModelProvider.notifier)
                                          .loadProgress();
                                    },
                                  ),

                                  SizedBox(height: buttonGap),

                                  GlossyGameButton.trophy(
                                    height: buttonHeight,
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LeaderboardView(),
                                        ),
                                      );
                                      ref
                                          .read(homeViewModelProvider.notifier)
                                          .loadProgress();
                                    },
                                  ),

                                  SizedBox(height: buttonGap),

                                  GlossyGameButton.settings(
                                    height: buttonHeight,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsView(),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: buttonGap),

                                  GlossyGameButton.profile(
                                    height: buttonHeight,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileView(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Minimal Terms & Conditions Link at bottom
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playClickSound();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsAndConditionsView(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 14,
                                      color: const Color(0xFFFFC610).withValues(alpha: 0.95),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Terms & Conditions',
                                      style: GoogleFonts.outfit(
                                        fontSize: isVeryCompact ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.92),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isVeryCompact ? 2 : 6),
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
