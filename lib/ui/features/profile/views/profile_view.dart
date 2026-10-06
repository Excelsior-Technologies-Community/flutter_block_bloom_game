import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/providers.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeViewModelProvider.notifier).loadProgress();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (number <= 0) return '0';
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _showEditProfileDialog(String currentName) {
    _nameController.text = currentName;
    _passwordController.clear();
    _confirmPasswordController.clear();
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Name Input Field (Wider, no card wrapper)
                      _buildDialogTextField(
                        controller: _nameController,
                        hintText: 'Enter Name',
                      ),

                      const SizedBox(height: 14),

                      // 2. Change Password Input Field
                      _buildDialogTextField(
                        controller: _passwordController,
                        hintText: 'Change Password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Confirm Password Input Field
                      _buildDialogTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 4. Action Buttons Row (CANCEL & EDIT)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // CANCEL Button (Increased dimensions: width: 155px, height: 40px)
                          SizedBox(
                            width: 155,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'CANCEL',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // EDIT Button (Increased dimensions: width: 155px, height: 40px, gradient #94C745 -> #1E4A0F)
                          Container(
                            width: 155,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF94C745),
                                  Color(0xFF1E4A0F),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(9.0),
                              border: Border.all(
                                color: const Color(0xFF527E27),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF94C745).withValues(alpha: 0.40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                              ),
                              onPressed: () {
                                final newName = _nameController.text.trim();
                                if (newName.isNotEmpty) {
                                  setState(() {});
                                  final repo = ref.read(progressRepositoryProvider);
                                  repo.getProgress().then((p) {
                                    repo.saveProgress(p, displayName: newName);
                                  });
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                'EDIT',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
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
          ),
        );
      },
    );
  }

  /// Text Field with distinct border pill, dark fill, and full width
  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090420),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.chakraPetch(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.chakraPetch(
            color: Colors.white70,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);

    final user = authState.user;
    final progress = homeState.progress;

    final defaultName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : ((user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : (user?.email != null && user!.email!.contains('@')
                ? user.email!.split('@').first
                : 'JAYMIN DABHODA'));

    final email = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : 'jaymin@xyz.com';

    final flowers = progress?.flowers ?? 2450;
    final highScore = progress?.highestScore ?? 24580;
    final levelCompleted = progress?.unlockedLevels ?? 120;

    return Scaffold(
      backgroundColor: const Color(0xFF001026),
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
                color: const Color(0xFF001026),
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Top Bar with Circular Back Button
                Positioned(
                  top: 12,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AudioService.instance.playClickSound();
                      Navigator.pop(context);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF001834),
                            border: Border.all(
                              color: const Color(0xFFFFC800),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        // Small Leaf Accent on bottom right of back button
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: Image.asset(
                            'assets/garden_leaf.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Centered Content View (Curved Title & Profile Card)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Curved Floral Title "PROFILE"
                        FloralHeaderTitle(
                          title: 'PROFILE',
                          fontSize: 34.0,
                          flowerSize: 42.0,
                          curveAmount: 14.0,
                          verticalOffset: -22.0,
                          letterSpacing: 2.0,
                        ),

                        const SizedBox(height: 24),

                        // Main Profile Card Container with Leaderboard Colors & back_design.png Background Image
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001834),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFC800),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            image: const DecorationImage(
                              image: AssetImage('assets/leaderboard_icons/back_design.png'),
                              fit: BoxFit.fill,
                              colorFilter: ColorFilter.mode(
                                Color(0xFF001834),
                                BlendMode.modulate,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. User Name + Edit Icon Box
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      defaultName.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showEditProfileDialog(defaultName),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC800),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Color(0xFF00152F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // 2. User Email
                              Text(
                                email,
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 3. Golden Ornamental Line Image (profile_line.png)
                              Image.asset(
                                'assets/profile_line.png',
                                height: 16,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 1,
                                  color: const Color(0xFFFFC800),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 4. Box 1: FLOWERS COLLECTED
                              _buildStatBox(
                                iconAsset: 'assets/sample.png',
                                fallbackIcon: Icons.local_florist_rounded,
                                iconColor: const Color(0xFFFF7BB0),
                                label: 'FLOWERS COLLECTED',
                                value: _formatNumber(flowers),
                              ),

                              const SizedBox(height: 14),

                              // 5. Box 2: HIGHEST SCORE
                              _buildStatBox(
                                iconAsset: 'assets/trophy_icon.png',
                                fallbackIcon: Icons.emoji_events_rounded,
                                iconColor: const Color(0xFFFFC800),
                                label: 'HIGHEST SCORE',
                                value: _formatNumber(highScore),
                              ),

                              const SizedBox(height: 14),

                              // 6. Box 3: LEVEL COMPLETED
                              _buildStatBox(
                                iconAsset: null,
                                fallbackIcon: Icons.star_rounded,
                                iconColor: const Color(0xFFFFC800),
                                label: 'LEVEL COMPLETED',
                                value: _formatNumber(levelCompleted),
                              ),

                              const SizedBox(height: 22),

                              // 7. BACK TO HOME Link
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  AudioService.instance.playClickSound();
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                    'BACK TO HOME',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF00A3FF),
                                      decoration: TextDecoration.underline,
                                      decorationColor: const Color(0xFF00A3FF),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  /// Individual Stat Box with Dark Background & Golden Border (#FFC800)
  Widget _buildStatBox({
    required String? iconAsset,
    required IconData fallbackIcon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF001026).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          SizedBox(
            width: 26,
            height: 26,
            child: iconAsset != null
                ? Image.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      fallbackIcon,
                      color: iconColor,
                      size: 24,
                    ),
                  )
                : Icon(
                    fallbackIcon,
                    color: iconColor,
                    size: 26,
                  ),
          ),

          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.chakraPetch(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Value
          Text(
            value,
            style: GoogleFonts.chakraPetch(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
