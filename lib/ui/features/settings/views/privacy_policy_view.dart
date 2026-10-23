import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
                        title: 'PRIVACY POLICY',
                        fontSize: 26.0,
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
                              Icons.verified_user_outlined,
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

                      // Central Privacy Card Container matching Settings & Leaderboard style
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
                              // Privacy Commitment Banner
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF065F46).withValues(alpha: 0.5),
                                      const Color(0xFF001834).withValues(alpha: 0.7),
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
                                    const Text('🔒', style: TextStyle(fontSize: 26)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'YOUR PRIVACY MATTERS',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFC800),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Block Bloom is designed with your privacy in mind. We collect only what is strictly required to save your progress and keep the game fair.',
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
                                      emoji: '🛡️',
                                      title: 'NO DATA SALE',
                                      subtitle: '100% Private',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '☁️',
                                      title: 'CLOUD SYNC',
                                      subtitle: 'Encrypted',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildHighlightCard(
                                      emoji: '👤',
                                      title: 'GUEST PLAY',
                                      subtitle: 'No Sign-in',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Section 1: Data We Collect
                              _buildPolicySection(
                                number: '01',
                                icon: Icons.badge_outlined,
                                title: 'INFORMATION WE COLLECT',
                                intro: 'We limit data collection to what is essential for core gameplay features:',
                                bulletPoints: [
                                  'Account Details: Display name and email if you choose to sign in with Google or Email (or a temporary anonymous guest ID).',
                                  'Game Progress: High score, levels cleared, unlocked garden flowers, and puzzle streaks.',
                                  'Device Diagnostics: Basic technical details (operating system version, screen resolution, crash logs) to optimize stability.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 2: How We Use Information
                              _buildPolicySection(
                                number: '02',
                                icon: Icons.tune_rounded,
                                title: 'HOW WE USE YOUR DATA',
                                intro: 'Your information is used strictly to provide and enhance your game experience:',
                                bulletPoints: [
                                  'To safely save, backup, and restore your floral garden across all your devices.',
                                  'To maintain accurate weekly and global rankings on the Leaderboard.',
                                  'To detect software glitches, prevent score tampering, and ensure fair play for all gardeners.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 3: Third-Party Services
                              _buildPolicySection(
                                number: '03',
                                icon: Icons.hub_outlined,
                                title: 'THIRD-PARTY SERVICES',
                                intro: 'We rely on trusted industry infrastructure to operate Block Bloom securely:',
                                bulletPoints: [
                                  'Firebase Authentication: Secure identity verification and sign-in services.',
                                  'Google Cloud Firestore: Encrypted remote database storage for your garden progress.',
                                  'We never sell, rent, or monetize your personal data with third-party advertisers.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 4: Data Security
                              _buildPolicySection(
                                number: '04',
                                icon: Icons.shield_outlined,
                                title: 'DATA SECURITY & STORAGE',
                                intro: 'Protecting your data is an ongoing priority for our team:',
                                bulletPoints: [
                                  'All network communication is encrypted end-to-end using HTTPS / TLS protocols.',
                                  'Strict Firestore security rules prevent unauthorized access to your account and game stats.',
                                  'Guest gameplay data remains stored locally on your device until an account is linked.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 5: Your Rights & Controls
                              _buildPolicySection(
                                number: '05',
                                icon: Icons.manage_accounts_outlined,
                                title: 'YOUR CHOICES & CONTROLS',
                                intro: 'You retain complete control over your gameplay data:',
                                bulletPoints: [
                                  'Play as a Guest at any time without submitting any personal email or phone number.',
                                  'Edit or customize your display name anytime through the Profile settings screen.',
                                  'Request complete account deletion and progress purge by contacting our support team.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 6: Children\'s Privacy
                              _buildPolicySection(
                                number: '06',
                                icon: Icons.child_care_rounded,
                                title: "CHILDREN'S PRIVACY",
                                intro: 'Block Bloom is a family-safe, peaceful puzzle game suitable for all ages:',
                                bulletPoints: [
                                  'We do not knowingly collect personal identifiable information from children under 13.',
                                  'If a parent or guardian discovers that a child has provided data without consent, please contact us for immediate deletion.',
                                ],
                              ),

                              _buildDivider(),

                              // Section 7: Updates & Inquiries
                              _buildPolicySection(
                                number: '07',
                                icon: Icons.contact_support_outlined,
                                title: 'UPDATES & INQUIRIES',
                                intro: 'We may periodically update this policy as new garden modes are introduced:',
                                bulletPoints: [
                                  'Material policy revisions will always be posted with a revised Last Updated date.',
                                  'For any questions or privacy requests, contact us at privacy@blockbloom.game.',
                                ],
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
                                  'Safe & secure block puzzle gardening. 🌸',
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

  // Individual Privacy Policy Section with proper indentation
  static Widget _buildPolicySection({
    required String number,
    required IconData icon,
    required String title,
    required String intro,
    required List<String> bulletPoints,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
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

          // Intro sentence with 38px left indentation
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              intro,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.55,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Indented Bullet Points
          ...bulletPoints.map((point) {
            return Padding(
              padding: const EdgeInsets.only(left: 38, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFFFFC800),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.outfit(
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.55,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
