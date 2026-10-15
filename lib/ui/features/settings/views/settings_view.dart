import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/features/auth/views/auth_view.dart';
import 'package:block_bloom/ui/providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late double _soundVolume;
  late double _musicVolume;
  late bool _hapticEnabled;

  @override
  void initState() {
    super.initState();
    _soundVolume = AudioService.instance.sfxVolume;
    _musicVolume = AudioService.instance.bgmVolume;
    _hapticEnabled = AudioService.instance.hapticEnabled;
  }

  void _showAboutDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0A172B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFFFC800),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    'BLOCK BLOOM',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 1.1',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Clear blocks, grow your garden, and enjoy a relaxing block puzzle experience.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC800),
                    foregroundColor: const Color(0xFF0A172B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF001026),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen Night Garden Background
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

          // Main Screen Content
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Navigation Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFFFFC610),
                              size: 30,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title: Arched SETTINGS with side flowers
                      const FloralHeaderTitle(
                        title: 'SETTINGS',
                        fontSize: 34.0,
                        flowerSize: 42.0,
                        curveAmount: 16.0,
                        verticalOffset: -22.0,
                        letterSpacing: 2.0,
                      ),

                      const SizedBox(height: 24),

                      // Central Settings Card Container matching Leaderboard card back exactly
                      Center(
                        child: Container(
                          width: math.min(size.width * 0.88, 350),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001834),
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage('assets/leaderboard_icons/back_design.png'),
                              fit: BoxFit.none,
                              repeat: ImageRepeat.repeat,
                              alignment: Alignment.center,
                              scale: 2.8,
                              colorFilter: ColorFilter.mode(
                                Color(0xFF001834),
                                BlendMode.modulate,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFFFFC800).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              foregroundPainter: _FiveStopGoldBorderPainter(
                                strokeWidth: 1.5,
                                radius: 16.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // SOUND Section
                                    _buildSectionHeader('SOUND'),
                                    const SizedBox(height: 12),
                                    _buildGoldSlider(
                                      value: _soundVolume,
                                      onChanged: (val) {
                                        setState(() => _soundVolume = val);
                                        AudioService.instance.setSfxVolume(val);
                                      },
                                    ),

                                    const SizedBox(height: 28),

                                    // MUSIC Section
                                    _buildSectionHeader('MUSIC'),
                                    const SizedBox(height: 12),
                                    _buildGoldSlider(
                                      value: _musicVolume,
                                      onChanged: (val) {
                                        setState(() => _musicVolume = val);
                                        AudioService.instance.setBgmVolume(val);
                                      },
                                    ),

                                    const SizedBox(height: 28),

                                    // HAPTIC Section
                                    _buildSectionHeader('HAPTIC'),
                                    const SizedBox(height: 12),
                                    _buildGoldSwitch(
                                      value: _hapticEnabled,
                                      onChanged: (val) {
                                        setState(() => _hapticEnabled = val);
                                        AudioService.instance.setHapticEnabled(val);
                                        AudioService.instance.playClickSound();
                                      },
                                    ),

                                    const SizedBox(height: 28),

                                    // USER ACCOUNT Section
                                    _buildSectionHeader('ACCOUNT'),
                                    const SizedBox(height: 10),
                                    Builder(
                                      builder: (context) {
                                        final authState = ref.watch(authViewModelProvider);
                                        final user = authState.user;
                                        return Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF000B1A),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: const Color(0xFF103975),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: const Color(0xFFFFC800),
                                                    child: Text(
                                                      user?.readableName.isNotEmpty == true
                                                          ? user!.readableName[0].toUpperCase()
                                                          : '🌸',
                                                      style: GoogleFonts.chakraPetch(
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFF001834),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          user?.readableName ?? 'Guest Gardener',
                                                          style: GoogleFonts.chakraPetch(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (user?.email != null)
                                                          Text(
                                                            user!.email!,
                                                            style: GoogleFonts.chakraPetch(
                                                              fontSize: 11,
                                                              color: Colors.white60,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF420914),
                                                foregroundColor: const Color(0xFFFF8080),
                                                side: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.logout_rounded, size: 18),
                                              label: Text(
                                                user?.isGuest == true ? 'LOG IN / SIGN UP' : 'LOG OUT',
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: () async {
                                                AudioService.instance.playClickSound();
                                                await ref.read(authViewModelProvider.notifier).logout();
                                                if (context.mounted) {
                                                  Navigator.of(context).pushAndRemoveUntil(
                                                    MaterialPageRoute(builder: (context) => const AuthView()),
                                                    (route) => false,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 28),

                                    // ABOUT APP Button Link
                                    GestureDetector(
                                      onTap: () => _showAboutDialog(context),
                                      child: Text(
                                        'ABOUT APP',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2096E7),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF2096E7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer: Version 1.1
                      Text(
                        'Version 1.1',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header with Gold Gradient Text
  Widget _buildSectionHeader(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        title,
        style: GoogleFonts.chakraPetch(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Custom Gold Slider with Flower Thumb matching design
  Widget _buildGoldSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbSize = 22.0;
        const thumbRadius = thumbSize / 2;
        final availableWidth = trackWidth - thumbSize;
        final thumbPosition = thumbRadius + (value * availableWidth);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final newValue = ((localPos.dx - thumbRadius) / availableWidth).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          onTapDown: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final newValue = ((localPos.dx - thumbRadius) / availableWidth).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Metallic Gold Gradient Track Bar (matching exact design in image)
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF6B3E05),
                        Color(0xFF9E6508),
                        Color(0xFFDCA427),
                        Color(0xFFFFDF6E),
                        Color(0xFFFFF6B2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                        blurRadius: 5,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),

                // Thumb Flower (🌸 sitting directly on the bar with no circular badge)
                Positioned(
                  left: thumbPosition - thumbRadius,
                  child: Image.asset(
                    'assets/game_flower.png',
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/small_flower.png',
                      width: thumbSize,
                      height: thumbSize,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        '🌸',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Custom Gold Toggle Switch (52px x 26px)
  Widget _buildGoldSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 26,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF814D00), Color(0xFF5A3403)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF2A1C0E), Color(0xFF4A341C)],
                ),
          border: Border.all(
            color: const Color(0xFFFFC800),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 21,
            height: 21,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF0A0), Color(0xFFE5A922)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to paint the 5-stop Gold gradient border matching Leaderboard card
class _FiveStopGoldBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double radius;

  _FiveStopGoldBorderPainter({
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius - strokeWidth / 2),
    );

    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFC800),
        Color(0xFF814D00),
        Color(0xFF6B4000),
        Color(0xFF814D00),
        Color(0xFFFFC800),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _FiveStopGoldBorderPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
}
