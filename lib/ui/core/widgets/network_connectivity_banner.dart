import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/data/services/network_service.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';

class NetworkConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NetworkConnectivityWrapper> createState() =>
      _NetworkConnectivityWrapperState();
}

class _NetworkConnectivityWrapperState
    extends ConsumerState<NetworkConnectivityWrapper>
    with TickerProviderStateMixin {
  late AnimationController _dialogAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseAnimController;
  late AnimationController _radarAnimController;
  late AnimationController _loadingRotateController;

  StreamSubscription<NetworkStatus>? _subscription;

  bool _isOffline = false;
  bool _isRestoredSuccess = false;
  bool _isManualChecking = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _dialogAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dialogAnimController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _dialogAnimController,
      curve: Curves.easeIn,
    );

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _loadingRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNetworkListener();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoDismissTimer?.cancel();
    _dialogAnimController.dispose();
    _pulseAnimController.dispose();
    _radarAnimController.dispose();
    _loadingRotateController.dispose();
    super.dispose();
  }

  Future<void> _initNetworkListener() async {
    final service = ref.read(networkServiceProvider);
    final initialStatus = await service.checkStatus();

    if (initialStatus == NetworkStatus.offline && mounted) {
      setState(() {
        _isOffline = true;
        _isRestoredSuccess = false;
      });
      _dialogAnimController.forward();
    }

    _subscription = service.onStatusChanged.listen((status) {
      if (!mounted) return;

      if (status == NetworkStatus.offline && !_isOffline) {
        _autoDismissTimer?.cancel();
        AudioService.instance.playClickSound();
        HapticFeedback.heavyImpact();

        setState(() {
          _isOffline = true;
          _isRestoredSuccess = false;
        });
        _dialogAnimController.forward();
      } else if (status == NetworkStatus.online && _isOffline) {
        _onConnectionRestored();
      }
    });
  }

  void _onConnectionRestored() {
    AudioService.instance.playClearSound();
    HapticFeedback.mediumImpact();

    setState(() {
      _isOffline = false;
      _isRestoredSuccess = true;
    });

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _dialogAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isRestoredSuccess = false;
            });
          }
        });
      }
    });
  }

  Future<void> _manualRetryCheck() async {
    if (_isManualChecking) return;
    setState(() {
      _isManualChecking = true;
    });
    HapticFeedback.lightImpact();

    final status = await ref.read(networkServiceProvider).checkStatus();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _isManualChecking = false;
    });

    if (status == NetworkStatus.online) {
      _onConnectionRestored();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Application View
        widget.child,

        // Network Connectivity Overlay
        if (_isOffline || _isRestoredSuccess)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildNewNetworkOverlay(context),
            ),
          ),
      ],
    );
  }

  /// NEW NETWORK CONNECTIVITY OVERLAY MATCHING FIGMA & IMAGE SPECIFICATIONS
  Widget _buildNewNetworkOverlay(BuildContext context) {
    final bool isOfflineMode = _isOffline;

    return Stack(
      children: [
        // Fullscreen Night Garden Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/splash_img.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF070B19),
            ),
          ),
        ),

        // Dark Semi-Transparent Vignette Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),

        // Center Content Container
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Network 3D Pedestal Icon (assets/network.png)
                  Image.asset(
                    'assets/network.png',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.wifi_off_rounded,
                      size: 100,
                      color: Color(0xFF459EC7),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title: "No Internet Connection"
                  Text(
                    isOfflineMode ? 'No Internet Connection' : 'Connection Restored!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle: "Please check your network settings and try again"
                  Text(
                    isOfflineMode
                        ? 'Please check your network settings\nand try again'
                        : 'Internet connection restored.\nResuming game...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // RETRY Button matching Figma Frame 140 Specs
                  _buildFigmaRetryButton(
                    text: isOfflineMode
                        ? (_isManualChecking ? 'CHECKING...' : 'RETRY')
                        : 'RESTORED',
                    onPressed: isOfflineMode
                        ? (_isManualChecking ? () {} : _manualRetryCheck)
                        : () {},
                    isLoading: _isManualChecking || !isOfflineMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// RETRY BUTTON WIDGET MATCHING FIGMA FRAME 140 DIMENSIONS & STYLES EXACTLY
  /// Layout: Horizontal, Width: Hug (min 103px), Height: Hug (44px)
  /// Radius: 10px, Border: 1px Linear Gradient (#275D7E to #9ACBF1)
  /// Fill: Linear Gradient (#459EC7 to #0E1E3C)
  /// Padding: Top 13px, Right 9px, Bottom 13px, Left 9px, Gap: 10px
  Widget _buildFigmaRetryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minWidth: 103),
        height: 44,
        padding: const EdgeInsets.all(1.0), // 1px linear gradient border thickness
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF275D7E), Color(0xFF9ACBF1)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF459EC7), Color(0xFF0E1E3C)],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rotating loading.png reference animation icon
              RotationTransition(
                turns: _loadingRotateController,
                child: Image.asset(
                  'assets/loading.png',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 10), // 10px gap as per Figma spec

              Text(
                text,
                style: GoogleFonts.chakraPetch(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* 
================================================================================
EXISTING DIALOG CODE COMMENTED OUT AS REQUESTED BY THE USER:
================================================================================

  Widget _buildGamifiedDialogCard(BuildContext context) {
    final bool isOfflineMode = _isOffline;

    final Color primaryGlowColor = isOfflineMode
        ? const Color(0xFFFF2E55)
        : const Color(0xFF00FF87);

    final Color borderStrokeColor = isOfflineMode
        ? const Color(0xFFFF9D00)
        : const Color(0xFF00E5FF);

    final List<Color> bgGradientColors = isOfflineMode
        ? const [Color(0xFF140209), Color(0xFF280010), Color(0xFF0A081D)]
        : const [Color(0xFF001A10), Color(0xFF003820), Color(0xFF081226)];

    final String titleText = isOfflineMode ? 'NO INTERNET CONNECTION' : 'CONNECTED!';
    final String subtitleText = isOfflineMode
        ? 'Please turn on Wi-Fi or Mobile Data to continue playing.'
        : 'Internet connection restored. Resuming game...';

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderStrokeColor,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGlowColor.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isOfflineMode)
                  AnimatedBuilder(
                    animation: _radarAnimController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(96, 96),
                        painter: _RadarRingsPainter(
                          progress: _radarAnimController.value,
                          pulseValue: _pulseAnimController.value,
                          color: primaryGlowColor,
                        ),
                      );
                    },
                  ),
                AnimatedBuilder(
                  animation: _pulseAnimController,
                  builder: (context, child) {
                    final double scale = isOfflineMode
                        ? 1.0 + (math.sin(_pulseAnimController.value * math.pi * 2) * 0.07)
                        : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryGlowColor.withValues(alpha: 0.35),
                              primaryGlowColor.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                          border: Border.all(color: primaryGlowColor, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGlowColor.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isOfflineMode
                                ? Icons.wifi_off_rounded
                                : Icons.check_circle_rounded,
                            color: primaryGlowColor,
                            size: 42,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isOfflineMode
                  ? const [Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFF2E55)]
                  : const [Color(0xFFFFFFFF), Color(0xFF70FFB8), Color(0xFF00FF87)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.8,
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            subtitleText,
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 22),

          if (isOfflineMode) ...[
            GreenGameButton(
              text: _isManualChecking ? 'CHECKING...' : 'RETRY CONNECTION',
              width: 230,
              height: 50,
              fontSize: 16,
              icon: _isManualChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
              onPressed: _isManualChecking ? () {} : _manualRetryCheck,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF87).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF87), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF00FF87),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RESUMING GAME...',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                      color: const Color(0xFF00FF87),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

class _RadarRingsPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final Color color;

  _RadarRingsPainter({
    required this.progress,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 2; i++) {
      final ringProgress = (progress + (i * 0.5)) % 1.0;
      final radius = 38.0 + (ringProgress * (maxRadius - 38.0));
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarRingsPainter oldDelegate) => true;
}
================================================================================
*/
