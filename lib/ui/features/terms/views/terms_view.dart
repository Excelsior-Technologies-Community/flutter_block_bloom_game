import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';
import 'package:block_bloom/ui/features/settings/views/privacy_policy_view.dart';

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = math.min(size.width * 0.90, 420);

    return Scaffold(
      backgroundColor: const Color(0xFF001026),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Night Garden Background
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF001026),
              ),
            ),
          ),

          // 2. Ambient Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Screen Content Structure
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Navigation Bar (Circular Gold Back Button)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              AudioService.instance.playClickSound();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF001834),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFC800),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFFFFC800),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Floral Arched Title
                      const FloralHeaderTitle(
                        title: 'TERMS & CONDITIONS',
                        fontSize: 24.0,
                        flowerSize: 34.0,
                        curveAmount: 12.0,
                        verticalOffset: -16.0,
                        letterSpacing: 1.5,
                      ),

                      const SizedBox(height: 10),

                      // Version & Last Updated Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001834).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFC800).withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 13,
                              color: Color(0xFFFFC800),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LAST UPDATED: OCTOBER 2026 • VERSION 1.1',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.90),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Central Terms Container
                      Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFF001834),
                          borderRadius: BorderRadius.circular(18),
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
                          border: Border.all(
                            color: const Color(0xFFFFC800),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFC800).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Overview Banner
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF065F46).withValues(alpha: 0.5),
                                      const Color(0xFF0F172A).withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🌸', style: TextStyle(fontSize: 26)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'WELCOME TO BLOCK BLOOM',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFC800),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Please review these terms before playing. By enjoying the game, you agree to these fair play & community guidelines.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.90),
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Fashionable 3-Card Highlights Row (Single Balanced Line)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '🎮',
                                      title: '100% FREE',
                                      subtitle: 'Puzzle Play',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '🛡️',
                                      title: 'FAIR PLAY',
                                      subtitle: 'Anti-Cheat',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '🔒',
                                      title: 'PROTECTED',
                                      subtitle: 'Safe Data',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Section 1: Introduction & Acceptance
                              _buildTermSection(
                                number: '01',
                                icon: Icons.handshake_outlined,
                                title: 'ACCEPTANCE OF TERMS',
                                content:
                                    'By downloading, installing, accessing, or playing Block Bloom ("the Game"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please discontinue using the Game.',
                              ),

                              _buildDivider(),

                              // Section 2: Personal License
                              _buildTermSection(
                                number: '02',
                                icon: Icons.key_outlined,
                                title: 'LICENSE TO PLAY',
                                content:
                                    'We grant you a non-exclusive, non-transferable, revocable, personal license to download and play Block Bloom for personal and non-commercial entertainment. You may not decompile, reverse-engineer, modify, or redistribute the game files or assets.',
                              ),

                              _buildDivider(),

                              // Section 3: Virtual Flowers & Items
                              _buildTermSection(
                                number: '03',
                                icon: Icons.local_florist_outlined,
                                title: 'VIRTUAL FLOWERS & PROGRESS',
                                content:
                                    'All in-game progress, high scores, flower collections, and garden items are virtual assets designed exclusively for gameplay entertainment. They hold no real-world cash value and cannot be redeemed, traded, or refunded outside the Game.',
                              ),

                              _buildDivider(),

                              // Section 4: Fair Play Policy
                              _buildTermSection(
                                number: '04',
                                icon: Icons.sports_esports_outlined,
                                title: 'FAIR PLAY & COMMUNITY',
                                content:
                                    'To ensure a fun and healthy atmosphere for every gardener, you agree not to use automation bots, exploits, third-party score modifiers, or hacks. Unfair manipulation of global or weekly leaderboards may result in score resets or profile bans.',
                              ),

                              _buildDivider(),

                              // Section 5: Accounts & Cloud Sync
                              _buildTermSection(
                                number: '05',
                                icon: Icons.cloud_sync_outlined,
                                title: 'USER ACCOUNTS & CLOUD SAVE',
                                content:
                                    'You may enjoy Block Bloom as a Guest or sign in using your account credentials (Email / Google). You are responsible for safeguarding your login credentials. We sync your progress with cloud servers so your garden thrives across all your devices.',
                              ),

                              _buildDivider(),

                              // Section 6: Intellectual Property
                              _buildTermSection(
                                number: '06',
                                icon: Icons.copyright_outlined,
                                title: 'INTELLECTUAL PROPERTY',
                                content:
                                    'All code, floral graphics, visual animations, puzzles, sound effects, and musical tracks in Block Bloom are protected by copyright and intellectual property laws. All rights are reserved by the developers.',
                              ),

                              _buildDivider(),

                              // Section 7: Disclaimers & Service
                              _buildTermSection(
                                number: '07',
                                icon: Icons.info_outline_rounded,
                                title: 'DISCLAIMERS & AVAILABILITY',
                                content:
                                    'Block Bloom is provided on an "as is" and "as available" basis. While we continuously strive to deliver a smooth and bug-free puzzle experience, occasional server updates, game enhancements, or bug fixes may occur without prior notice.',
                              ),

                              _buildDivider(),

                              // Section 8: Privacy & Data Protection
                              _buildTermSection(
                                number: '08',
                                icon: Icons.security_rounded,
                                title: 'PRIVACY & DATA HANDLING',
                                content:
                                    'We care deeply about your privacy. Only essential gameplay metrics, scores, and account identifiers are handled in accordance with modern security standards. We never sell your personal information to third parties.',
                                extraWidget: GestureDetector(
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
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'View Privacy Policy →',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2096E7),
                                        decoration: TextDecoration.underline,
                                        decorationColor: const Color(0xFF2096E7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              // Section 9: Updates to Terms
                              _buildTermSection(
                                number: '09',
                                icon: Icons.update_rounded,
                                title: 'CHANGES TO TERMS',
                                content:
                                    'We reserve the right to revise these Terms whenever new game modes or features are introduced. Continued use of Block Bloom after updates indicates your full acceptance of the revised Terms.',
                              ),

                              _buildDivider(),

                              // Section 10: Contact & Support
                              _buildTermSection(
                                number: '10',
                                icon: Icons.support_agent_rounded,
                                title: 'CONTACT & SUPPORT',
                                content:
                                    'If you have inquiries, garden suggestions, or need assistance, visit our in-app Support screen or contact our team directly at support@blockbloom.game. We are always happy to help our community grow!',
                              ),

                              const SizedBox(height: 24),

                              // Bottom Acknowledgment Action Button
                              Center(
                                child: GlossyGameButton.green(
                                  text: 'I UNDERSTAND',
                                  height: 46,
                                  width: 180,
                                  fontSize: 16,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    AudioService.instance.playClickSound();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Game Motto Footer
                              Center(
                                child: Text(
                                  'Bloom your garden, one block at a time. 🌸',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
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

  // Fashionable 3-Card Feature Micro-Card
  static Widget _buildHighlightCard({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF001026).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFFFFC800).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC800).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFC800).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFE082),
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.80),
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Individual Term Section
  static Widget _buildTermSection({
    required String number,
    required IconData icon,
    required String title,
    required String content,
    Widget? extraWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gold Number Tag
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC800),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.45),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  number,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001834),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Icon(
                icon,
                size: 18,
                color: const Color(0xFFFFC800),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.55,
                    letterSpacing: 0.2,
                  ),
                ),
                if (extraWidget != null) extraWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Subtle separator between clauses
  static Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFFC800).withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
