import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
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
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                const Spacer(),

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

                // Central Settings Card Container (#001834)
                Center(
                  child: Container(
                    width: math.min(size.width * 0.88, 350),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001834).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFC800),
                        width: 1.5,
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

                        const SizedBox(height: 32),

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

                const Spacer(flex: 2),

                // Footer: Version 1.1
                Text(
                  'Version 1.1',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 24),
              ],
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

  // Custom Gold Slider with Flower Thumb
  Widget _buildGoldSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbRadius = 14.0;
        final availableWidth = trackWidth - (thumbRadius * 2);
        final thumbPosition = thumbRadius + (value * availableWidth);

        return GestureDetector(
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
                // Inactive Background Track (Dark Brown Gold)
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A240A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF814D00),
                      width: 1,
                    ),
                  ),
                ),

                // Active Progress Track (Gold Gradient)
                Container(
                  height: 8,
                  width: (thumbPosition).clamp(0.0, trackWidth),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF814D00), Color(0xFFFFC610)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Thumb Flower (Using assets/small_flower.png)
                Positioned(
                  left: thumbPosition - thumbRadius,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF4DD),
                      border: Border.all(
                        color: const Color(0xFFFFC610),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/small_flower.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          '🌸',
                          style: TextStyle(fontSize: 14),
                        ),
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

  // Custom Gold Toggle Switch (44px x 22px)
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
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF814D00), Color(0xFFFFC610)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF2A1C0E), Color(0xFF4A341C)],
                ),
          border: Border.all(
            color: const Color(0xFFFFC800),
            width: 1.2,
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
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF7ED),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
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
