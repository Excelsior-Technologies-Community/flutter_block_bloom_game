import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/data/services/network_service.dart';

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
  late Animation<double> _fadeAnimation;
  late AnimationController _loadingRotateController;

  StreamSubscription<NetworkStatus>? _subscription;

  bool _isOffline = false;
  bool _isLoadingOnline = false;
  bool _isManualChecking = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _dialogAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _dialogAnimController,
      curve: Curves.easeInOut,
    );

    _loadingRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialNetworkStatus();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoDismissTimer?.cancel();
    _dialogAnimController.dispose();
    _loadingRotateController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialNetworkStatus() async {
    final service = ref.read(networkServiceProvider);
    final initialStatus = await service.checkStatus();

    if (initialStatus == NetworkStatus.offline && mounted) {
      setState(() {
        _isOffline = true;
        _isLoadingOnline = false;
      });
      _dialogAnimController.value = 1.0;
    }
  }

  void _onConnectionRestored() {
    if (_isLoadingOnline && !_isOffline) return;

    AudioService.instance.playClearSound();
    HapticFeedback.mediumImpact();

    _autoDismissTimer?.cancel();

    setState(() {
      _isOffline = false;
      _isLoadingOnline = true;
    });

    // Ensure overlay is 100% visible during loading transition
    _dialogAnimController.value = 1.0;

    // Show Loading screen for 3.0 seconds, then smoothly fade out to normal app view
    _autoDismissTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _dialogAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingOnline = false;
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

    await Future.delayed(const Duration(milliseconds: 400));
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
    // Listen to network status changes via Riverpod for 100% reliable state updates
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      final status = next.value;
      if (status == null) return;

      if (status == NetworkStatus.offline && !_isOffline) {
        _autoDismissTimer?.cancel();
        AudioService.instance.playClickSound();
        HapticFeedback.heavyImpact();

        setState(() {
          _isOffline = true;
          _isLoadingOnline = false;
        });
        _dialogAnimController.value = 1.0;
      } else if (status == NetworkStatus.online && _isOffline) {
        _onConnectionRestored();
      }
    });

    return Stack(
      children: [
        // Main Application View
        widget.child,

        // Network Connectivity Overlay
        if (_isOffline || _isLoadingOnline)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: DefaultTextStyle(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: _buildNewNetworkOverlay(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewNetworkOverlay(BuildContext context) {
    if (_isLoadingOnline) {
      return _buildLoadingOverlay(context);
    }
    return _buildOfflineOverlay(context);
  }

  /// LOADING OVERLAY SHOWN WHEN BACK ONLINE / CONNECTED (MATCHES IMAGE SPEC)
  Widget _buildLoadingOverlay(BuildContext context) {
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

        // Dark Semi-Transparent Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.40),
          ),
        ),

        // Centered Loading Content matching design spec
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rotating assets/loading.png icon
              RotationTransition(
                turns: _loadingRotateController,
                child: Image.asset(
                  'assets/loading.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // "Loading..." text without yellow underline
              Text(
                'Loading...',
                textAlign: TextAlign.center,
                style: GoogleFonts.chakraPetch(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// OFFLINE OVERLAY SHOWN WHEN OFF WIFI / NO INTERNET (NO YELLOW UNDERLINES)
  Widget _buildOfflineOverlay(BuildContext context) {
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

        // Dark Semi-Transparent Overlay
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
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle: "Please check your network settings and try again"
                  Text(
                    'Please check your network settings\nand try again',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // RETRY Button matching Figma Frame 140 Specs
                  _buildFigmaRetryButton(
                    text: _isManualChecking ? 'CHECKING...' : 'RETRY',
                    onPressed: _isManualChecking ? () {} : _manualRetryCheck,
                    isLoading: _isManualChecking,
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
        padding: const EdgeInsets.all(1.0),
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
              if (isLoading)
                RotationTransition(
                  turns: _loadingRotateController,
                  child: Image.asset(
                    'assets/loading.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
              else
                Image.asset(
                  'assets/loading.png',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

              const SizedBox(width: 10),

              Text(
                text,
                style: GoogleFonts.chakraPetch(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  height: 1.0,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


