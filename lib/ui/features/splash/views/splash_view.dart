import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/ui/features/auth/views/auth_view.dart';
import 'package:block_bloom/ui/features/home/views/home_view.dart';
import 'package:block_bloom/ui/features/splash/widgets/gaming_loading_bar.dart';
import 'package:block_bloom/ui/providers.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late AnimationController _progressController;
  late Animation<double> _curvedProgress;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Subtle pulsing/breathing animation for the central game logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    // 1-100% progress animation controller (~8.3 seconds total for immersive pacing)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    );

    _curvedProgress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // Kick off initialization and progress loading sequence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoadingSequence();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startLoadingSequence() async {
    // 1. Warm up auth & user state in background
    ref.read(authViewModelProvider);

    // 2. Smoothly advance progress bar to 92% at an unhurried, steady gaming pace (6.2s)
    try {
      await _progressController.animateTo(
        0.92,
        duration: const Duration(milliseconds: 6200),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}

    // 3. Ensure auth state initialization is complete
    var authState = ref.read(authViewModelProvider);
    if (!authState.isInitialized) {
      while (!authState.isInitialized && mounted) {
        await Future.delayed(const Duration(milliseconds: 50));
        authState = ref.read(authViewModelProvider);
      }
    }

    if (!mounted) return;

    // 4. Smoothly advance from 92% to 100% (1.4s)
    try {
      await _progressController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeInQuad,
      );
    } catch (_) {}

    // 5. Rewarding pause at 100% with intact border before transitioning
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    // Route to HomeView if authenticated, otherwise to AuthView
    final Widget targetScreen =
        authState.isAuthenticated ? const HomeView() : const AuthView();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),

          // Deep ambient gradient overlay for cinematic contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ambient Floating Petal Particles Background
          const Positioned.fill(child: PetalParticleField()),

          // Main Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Center Splash Icon with Pulsing Animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SizedBox(
                            width: math.min(size.width * 0.78, 320),
                            child: Image.asset(
                              'assets/splash_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text(
                                  'BLOCK BLOOM',
                                  style: TextStyle(
                                    fontFamily: 'BebasNeue',
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Spacing directly matching previous Play button location
                  const SizedBox(height: 36),

                  // Modern Cyber/Arcade Gaming Loading Bar positioned exactly where Play button was
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return GamingLoadingBar(
                        progress: _curvedProgress.value,
                        width: math.min(size.width * 0.84, 320),
                      );
                    },
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
