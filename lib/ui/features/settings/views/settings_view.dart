import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/features/auth/views/auth_view.dart';
import 'package:block_bloom/ui/features/terms/views/terms_view.dart';
import 'package:block_bloom/ui/features/settings/views/privacy_policy_view.dart';
import 'package:block_bloom/ui/features/settings/views/how_to_play_view.dart';
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
  late HapticLevel _hapticLevel;

  @override
  void initState() {
    super.initState();
    _soundVolume = AudioService.instance.sfxVolume;
    _musicVolume = AudioService.instance.bgmVolume;
    _hapticEnabled = AudioService.instance.hapticEnabled;
    _hapticLevel = AudioService.instance.hapticLevel;
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

  // Elegant Gold Shimmer Divider
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFFFC800).withValues(alpha: 0.45),
            const Color(0xFFFFC800).withValues(alpha: 0.8),
            const Color(0xFFFFC800).withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  // Confirmation Dialog for Account Deletion
  void _showDeleteAccountDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFF001834),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF420914),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF3B30), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFFF8080),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'DELETE ACCOUNT?',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This action cannot be undone. All your garden blooms, scores, and saved progress will be permanently erased.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          AudioService.instance.playClickSound();
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          AudioService.instance.playClickSound();
                          Navigator.pop(dialogContext);
                          await ref.read(authViewModelProvider.notifier).deleteAccount();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const AuthView()),
                              (route) => false,
                            );
                          }
                        },
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          SafeArea(
            child: Stack(
              children: [
                // Centered Screen Content (SETTINGS Title + Card + Version 1.1)
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title: Arched SETTINGS with side flowers matching reference image
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
                                    // SOUND Section (Row: Left text, Right scrolling slider)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 90,
                                          alignment: Alignment.centerLeft,
                                          child: _buildSectionHeader('SOUND'),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGoldSlider(
                                            value: _soundVolume,
                                            onChanged: (val) {
                                              setState(() => _soundVolume = val);
                                              AudioService.instance.setSfxVolume(val);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // MUSIC Section (Row: Left text, Right scrolling slider)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 90,
                                          alignment: Alignment.centerLeft,
                                          child: _buildSectionHeader('MUSIC'),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGoldSlider(
                                            value: _musicVolume,
                                            onChanged: (val) {
                                              setState(() => _musicVolume = val);
                                              AudioService.instance.setBgmVolume(val);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // HAPTIC Section (Row: Left text, Middle Dropdown, Right toggle switch)
                                    SizedBox(
                                      height: 36,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          _buildSectionHeader('HAPTIC'),
                                          const Spacer(),
                                          _buildHapticDropdown(),
                                          const SizedBox(width: 10),
                                          _buildGoldSwitch(
                                            value: _hapticEnabled,
                                            onChanged: (val) {
                                              setState(() => _hapticEnabled = val);
                                              AudioService.instance.setHapticEnabled(val);
                                              if (val) {
                                                AudioService.instance.triggerHaptic(null, true);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // --- COMMENTED OUT: ACCOUNT & USER / GUEST GARDENER VIEW (TEMPORARILY DISABLED AS REQUESTED) ---
                                    // const SizedBox(height: 20),
                                    // SizedBox(
                                    //   height: 36,
                                    //   child: Row(
                                    //     crossAxisAlignment: CrossAxisAlignment.center,
                                    //     children: [
                                    //       _buildSectionHeader('ACCOUNT', fontSize: 22),
                                    //       const Spacer(),
                                    //       Flexible(
                                    //         child: Builder(
                                    //           builder: (context) {
                                    //             final authState = ref.watch(authViewModelProvider);
                                    //             final user = authState.user;
                                    //             return Text(
                                    //               user?.readableName ?? 'Guest Gardener',
                                    //               style: GoogleFonts.chakraPetch(
                                    //                 fontSize: 15,
                                    //                 fontWeight: FontWeight.bold,
                                    //                 color: const Color(0xFFFFC800),
                                    //                 letterSpacing: 0.4,
                                    //               ),
                                    //               maxLines: 1,
                                    //               overflow: TextOverflow.ellipsis,
                                    //               textAlign: TextAlign.end,
                                    //             );
                                    //           },
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // Builder(
                                    //   builder: (context) {
                                    //     final authState = ref.watch(authViewModelProvider);
                                    //     final user = authState.user;
                                    //     return Container(
                                    //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    //       decoration: BoxDecoration(
                                    //         color: const Color(0xFF000B1A),
                                    //         borderRadius: BorderRadius.circular(14),
                                    //         border: Border.all(
                                    //           color: const Color(0xFF103975),
                                    //           width: 1.0,
                                    //         ),
                                    //       ),
                                    //       child: Row(
                                    //         children: [
                                    //           CircleAvatar(
                                    //             radius: 17,
                                    //             backgroundColor: const Color(0xFFFFC800),
                                    //             child: Text(
                                    //               user?.readableName.isNotEmpty == true
                                    //                   ? user!.readableName[0].toUpperCase()
                                    //                   : '🌸',
                                    //               style: GoogleFonts.chakraPetch(
                                    //                 fontWeight: FontWeight.bold,
                                    //                 color: const Color(0xFF001834),
                                    //                 fontSize: 15,
                                    //               ),
                                    //             ),
                                    //           ),
                                    //           const SizedBox(width: 12),
                                    //           Expanded(
                                    //             child: Column(
                                    //               crossAxisAlignment: CrossAxisAlignment.start,
                                    //               children: [
                                    //                 Text(
                                    //                   user?.readableName ?? 'Guest Gardener',
                                    //                   style: GoogleFonts.chakraPetch(
                                    //                     fontSize: 13.5,
                                    //                     fontWeight: FontWeight.bold,
                                    //                     color: Colors.white,
                                    //                   ),
                                    //                   maxLines: 1,
                                    //                   overflow: TextOverflow.ellipsis,
                                    //                 ),
                                    //                 if (user?.email != null)
                                    //                   Text(
                                    //                     user!.email!,
                                    //                     style: GoogleFonts.chakraPetch(
                                    //                       fontSize: 11,
                                    //                       color: Colors.white60,
                                    //                     ),
                                    //                     maxLines: 1,
                                    //                     overflow: TextOverflow.ellipsis,
                                    //                   ),
                                    //               ],
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //     );
                                    //   },
                                    // ),

                                    // Elegant Gold Shimmer Divider
                                    _buildDivider(),

                                    // HOW TO PLAY Action Card
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        AudioService.instance.playClickSound();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const HowToPlayView(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF065F46).withValues(alpha: 0.85),
                                              const Color(0xFF001834),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFFFC800),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFFC800).withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.sports_esports_rounded,
                                              color: Color(0xFFFFC800),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'HOW TO PLAY',
                                              style: GoogleFonts.chakraPetch(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Color(0xFFFFC800),
                                              size: 13,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Elegant Gold Shimmer Divider
                                    _buildDivider(),

                                    // LOGOUT & DELETE Buttons Row
                                    Builder(
                                      builder: (context) {
                                        final authState = ref.watch(authViewModelProvider);
                                        final user = authState.user;
                                        return Row(
                                          children: [
                                            // LOG OUT / LOG IN Button
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF420914),
                                                  foregroundColor: const Color(0xFFFF8080),
                                                  side: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                                  elevation: 4,
                                                  shadowColor: Colors.black.withValues(alpha: 0.5),
                                                ),
                                                icon: const Icon(Icons.logout_rounded, size: 16),
                                                label: Text(
                                                  user?.isGuest == true ? 'LOG IN' : 'LOG OUT',
                                                  style: GoogleFonts.chakraPetch(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
                                            ),
                                            const SizedBox(width: 12),
                                            // DELETE Button
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2E090E),
                                                  foregroundColor: const Color(0xFFFF6B6B),
                                                  side: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                                  elevation: 4,
                                                  shadowColor: Colors.black.withValues(alpha: 0.5),
                                                ),
                                                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                                                label: Text(
                                                  'DELETE',
                                                  style: GoogleFonts.chakraPetch(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                onPressed: () {
                                                  AudioService.instance.playClickSound();
                                                  _showDeleteAccountDialog(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 18),

                                    // ABOUT APP • TERMS • PRIVACY POLICY Links
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showAboutDialog(context),
                                          child: Text(
                                            'ABOUT APP',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2096E7),
                                              decoration: TextDecoration.underline,
                                              decorationColor: const Color(0xFF2096E7),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            AudioService.instance.playClickSound();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const TermsAndConditionsView(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'TERMS',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2096E7),
                                              decoration: TextDecoration.underline,
                                              decorationColor: const Color(0xFF2096E7),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            AudioService.instance.playClickSound();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const PrivacyPolicyView(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'PRIVACY POLICY',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 13.5,
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

              // Fixed Top Navigation (Back button at top-left matching reference image)
              Positioned(
                top: 12,
                left: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AudioService.instance.playClickSound();
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFFFFC610),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  // Section Header with Gold Gradient Text
  Widget _buildSectionHeader(String title, {double fontSize = 24}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        title,
        style: GoogleFonts.chakraPetch(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Custom Gold Slider with Flower Thumb matching Figma design (224px x 7px)
  // Left side: #6D4201, Right side: #FFFFFF -> #F9CC70 gradient, Border: 0.75px 5-stop gold
  Widget _buildGoldSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double figmaTrackWidth = 224.0;
        const double trackHeight = 7.0;
        const double thumbSize = 28.0;
        const double thumbRadius = thumbSize / 2;
        const double sliderHeight = 36.0;

        final maxWidth = constraints.maxWidth;
        // Exact 224px track width from Figma, capped only if screen width is smaller than track + thumb
        final trackWidth = math.min(figmaTrackWidth, maxWidth - thumbSize);
        final trackLeft = (maxWidth - trackWidth) / 2;
        final fillWidth = (value * trackWidth).clamp(0.0, trackWidth);
        final thumbCenter = trackLeft + fillWidth;

        void updateValue(Offset localPosition) {
          final dxOnTrack = localPosition.dx - trackLeft;
          final newValue = (dxOnTrack / trackWidth).clamp(0.0, 1.0);
          if ((newValue - value).abs() > 0.001) {
            onChanged(newValue);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => updateValue(details.localPosition),
          onHorizontalDragUpdate: (details) => updateValue(details.localPosition),
          onTapDown: (details) => updateValue(details.localPosition),
          child: SizedBox(
            height: sliderHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // 224px x 7px Capsule Track Container centered horizontally
                Positioned(
                  left: trackLeft,
                  top: (sliderHeight - trackHeight) / 2,
                  width: trackWidth,
                  height: trackHeight,
                  child: CustomPaint(
                    foregroundPainter: const _GoldSliderTrackBorderPainter(
                      strokeWidth: 0.75,
                      radius: 204.0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(204.0),
                      child: Stack(
                        children: [
                          // Base/Right side Track (Rectangle 43 in Figma: #FFFFFF -> #F9CC70 gradient)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF9CC70),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Left side Active Track (Rectangle 44 in Figma: #6D4201 solid)
                          // Dynamically tracks the flower scroll position
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: fillWidth,
                            child: Container(
                              color: const Color(0xFF6D4201),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Thumb Flower (🌸 sitting directly centered over the left/right division)
                Positioned(
                  left: thumbCenter - thumbRadius,
                  top: (sliderHeight - thumbSize) / 2,
                  child: IgnorePointer(
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
                          style: TextStyle(fontSize: 18),
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

  // Custom Gold Dropdown for Haptic Intensity Levels (Slow, Middle, High, Extreme)
  Widget _buildHapticDropdown() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001428),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFC800),
          width: 1.1,
        ),
        boxShadow: _hapticEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC800).withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HapticLevel>(
          value: _hapticLevel,
          isDense: true,
          dropdownColor: const Color(0xFF001834),
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFFFFC800),
            size: 20,
          ),
          onChanged: (HapticLevel? newLevel) {
            if (newLevel != null) {
              setState(() {
                _hapticLevel = newLevel;
                _hapticEnabled = true;
              });
              AudioService.instance.setHapticLevel(newLevel);
            }
          },
          items: HapticLevel.values.map((HapticLevel level) {
            final isSelected = level == _hapticLevel;
            return DropdownMenuItem<HapticLevel>(
              value: level,
              child: Text(
                level.label,
                style: GoogleFonts.chakraPetch(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFFFFC800) : Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }).toList(),
        ),
      ),
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

/// Custom painter for the 0.75px 5-stop gold gradient track border matching Figma Rectangle 43
class _GoldSliderTrackBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double radius;

  const _GoldSliderTrackBorderPainter({
    this.strokeWidth = 0.75,
    this.radius = 204.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFC800),
        Color(0xFF814D00),
        Color(0xFF884000),
        Color(0xFF814D00),
        Color(0xFFFFC800),
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldSliderTrackBorderPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
}
