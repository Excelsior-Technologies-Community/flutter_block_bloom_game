import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/ui/features/auth/views/auth_view.dart';
import 'package:block_bloom/ui/features/home/views/home_view.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';
import 'package:block_bloom/ui/providers.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePlayNow() async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });
    AudioService.instance.playClickSound();

    var authState = ref.read(authViewModelProvider);
    if (!authState.isInitialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        authState = ref.read(authViewModelProvider);
        return !authState.isInitialized;
      });
    }

    final Widget targetScreen = authState.isAuthenticated ? const HomeView() : const AuthView();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
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

          // Main Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Center Splash Icon
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

                  const SizedBox(height: 36),

                  // Glossy App Button: PLAY NOW
                  SizedBox(
                    width: math.min(size.width * 0.75, 280),
                    child: GlossyGameButton.play(
                      text: 'PLAY NOW',
                      onPressed: _handlePlayNow,
                    ),
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
