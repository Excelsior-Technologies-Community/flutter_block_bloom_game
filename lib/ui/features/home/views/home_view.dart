import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';
import 'package:block_bloom/ui/features/level_select/views/level_select_view.dart';
import 'package:block_bloom/ui/features/garden/views/garden_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_intro_view.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_over_view.dart';
import 'package:block_bloom/ui/features/settings/views/settings_view.dart';
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Center Logo (home_icon.png)
                  Center(
                    child: SizedBox(
                      width: math.min(size.width * 0.80, 310),
                      child: Image.asset(
                        'assets/home_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
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

                  const SizedBox(height: 12),

                  // Subtitle Text
                  Text(
                    'Bloom your garden,\none block at a time.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.3,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Centered Glossy Game Buttons Stack
                  SizedBox(
                    width: math.min(size.width * 0.85, 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlossyGameButton.play(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LevelSelectView(),
                                    ),
                                  );
                                  ref.read(homeViewModelProvider.notifier).loadProgress();
                                },
                        ),

                        const SizedBox(height: 14),

                        GlossyGameButton.dailyGarden(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DailyGardenIntroView(),
                              ),
                            );
                            ref.read(homeViewModelProvider.notifier).loadProgress();
                          },
                        ),

                        const SizedBox(height: 14),

                        GlossyGameButton.garden(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GardenView(),
                              ),
                            );
                            ref.read(homeViewModelProvider.notifier).loadProgress();
                          },
                        ),

                        const SizedBox(height: 14),

                        GlossyGameButton.trophy(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DailyGardenGameOverView(),
                              ),
                            );
                            ref.read(homeViewModelProvider.notifier).loadProgress();
                          },
                        ),

                        const SizedBox(height: 14),

                        GlossyGameButton.settings(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsView(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
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
