import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/game_avatar.dart';
import 'package:block_bloom/ui/core/utils/app_validators.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/game_avatar_widget.dart';
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

    final currentUser = ref.read(authViewModelProvider).user;
    final isGoogleUser = currentUser?.authProvider == 'google';
    String? selectedAvatar = currentUser?.photoUrl;
    final initialLetter = (currentName.trim().isNotEmpty ? currentName.trim()[0] : 'A').toUpperCase();

    if (!mounted) return;
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        String? nameError;
        String? passwordError;
        String? confirmPasswordError;
        bool isSubmitting = false;

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001834),
                    borderRadius: BorderRadius.circular(20),
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title Bar with EDIT PROFILE & Close Button
                        Row(
                          children: [
                            const SizedBox(width: 28),
                            Expanded(
                              child: Text(
                                'EDIT PROFILE',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playClickSound();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Centered Circle Profile Avatar with Edit Badge
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              AudioService.instance.playClickSound();
                              final choice = await _showChangePhotoOptions(context);
                              if (!context.mounted || choice == null) return;

                              if (choice == 'CHOOSE_CATALOG') {
                                final picked = await _showAvatarSelectionDialog(context, selectedAvatar);
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedAvatar = picked;
                                  });
                                }
                              } else if (choice == 'CHOOSE_STORAGE') {
                                final picked = await _pickImageFromStorage(context);
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedAvatar = picked;
                                  });
                                }
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                GameAvatarWidget(
                                  avatarIdOrUrl: selectedAvatar,
                                  fallbackLetter: initialLetter,
                                  size: 88,
                                  showBorder: true,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFE066),
                                          Color(0xFFFFC800),
                                          Color(0xFFD47A00),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF00152F),
                                        width: 2.0,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 15,
                                      color: Color(0xFF00152F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle: Tap avatar to change
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            AudioService.instance.playClickSound();
                            final choice = await _showChangePhotoOptions(context);
                            if (!context.mounted || choice == null) return;

                            if (choice == 'CHOOSE_CATALOG') {
                              final picked = await _showAvatarSelectionDialog(context, selectedAvatar);
                              if (picked != null) {
                                setDialogState(() {
                                  selectedAvatar = picked;
                                });
                              }
                            } else if (choice == 'CHOOSE_STORAGE') {
                              final picked = await _pickImageFromStorage(context);
                              if (picked != null) {
                                setDialogState(() {
                                  selectedAvatar = picked;
                                });
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 13,
                                color: Color(0xFFFFC800),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tap avatar to change',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFC800),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                      // 1. Name Input Field with Validation
                      _buildDialogTextField(
                        controller: _nameController,
                        hintText: 'Enter Name',
                        errorText: nameError,
                        onChanged: (val) {
                          if (nameError != null) {
                            setDialogState(() {
                              nameError = AppValidators.validateName(val, isRequired: true);
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // 2. Change Password Input Field with Validation
                      _buildDialogTextField(
                        controller: _passwordController,
                        hintText: isGoogleUser ? 'Set Password (Optional)' : 'Change Password (Min 6 chars)',
                        obscureText: _obscurePassword,
                        errorText: passwordError,
                        onChanged: (val) {
                          if (passwordError != null || confirmPasswordError != null) {
                            setDialogState(() {
                              passwordError = val.isNotEmpty
                                  ? AppValidators.validatePassword(val, isRequired: false)
                                  : null;
                              if (confirmPasswordError != null && _confirmPasswordController.text.isNotEmpty) {
                                confirmPasswordError = AppValidators.validateConfirmPassword(
                                  _confirmPasswordController.text,
                                  val,
                                  isRequired: val.isNotEmpty,
                                );
                              }
                            });
                          }
                        },
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

                      // 3. Confirm Password Input Field with Validation
                      _buildDialogTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        errorText: confirmPasswordError,
                        onChanged: (val) {
                          if (confirmPasswordError != null) {
                            setDialogState(() {
                              confirmPasswordError = AppValidators.validateConfirmPassword(
                                val,
                                _passwordController.text,
                                isRequired: _passwordController.text.isNotEmpty,
                              );
                            });
                          }
                        },
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

                      // 4. Action Buttons Row (CANCEL & SAVE)
                      Row(
                        children: [
                          // CANCEL Button
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onPressed: isSubmitting ? null : () => Navigator.pop(context),
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
                          ),

                          const SizedBox(width: 14),

                          // SAVE Button
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF94C745),
                                    Color(0xFF1E4A0F),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
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
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                      FocusScope.of(context).unfocus();
                                      AudioService.instance.playClickSound();

                                      final newName = _nameController.text;
                                      final newPass = _passwordController.text;
                                      final confirmPass = _confirmPasswordController.text;

                                      // Run proper field validations
                                      final nameErr = AppValidators.validateName(newName, isRequired: true);
                                      final passErr = newPass.isNotEmpty
                                          ? AppValidators.validatePassword(newPass, isRequired: false)
                                          : null;
                                      final confirmErr = (newPass.isNotEmpty || confirmPass.isNotEmpty)
                                          ? AppValidators.validateConfirmPassword(
                                              confirmPass,
                                              newPass,
                                              isRequired: newPass.isNotEmpty,
                                            )
                                          : null;

                                      if (nameErr != null || passErr != null || confirmErr != null) {
                                        HapticFeedback.heavyImpact();
                                        setDialogState(() {
                                          nameError = nameErr;
                                          passwordError = passErr;
                                          confirmPasswordError = confirmErr;
                                        });
                                        return;
                                      }

                                      setDialogState(() {
                                        nameError = null;
                                        passwordError = null;
                                        confirmPasswordError = null;
                                        isSubmitting = true;
                                      });

                                      try {
                                        await ref.read(authViewModelProvider.notifier).updateUserProfile(
                                          displayName: newName.trim(),
                                          newPassword: newPass.isNotEmpty ? newPass : null,
                                          photoUrl: selectedAvatar,
                                        );

                                        final repo = ref.read(progressRepositoryProvider);
                                        final p = await repo.getProgress();
                                        await repo.saveProgress(
                                          p,
                                          displayName: newName.trim(),
                                          photoUrl: selectedAvatar,
                                        );

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Profile updated successfully!'),
                                              backgroundColor: Color(0xFF10B981),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setDialogState(() {
                                            isSubmitting = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString().replaceAll('Exception: ', '')),
                                              backgroundColor: const Color(0xFFFF3B30),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'SAVE',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        ),
      );
    },
  );
}

  /// Popup dialog displaying 10-15 avatars in a glossy game grid for selection
  Future<String?> _showAvatarSelectionDialog(
    BuildContext context,
    String? currentSelected,
  ) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogCtx) {
        String? tempSelected = currentSelected;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: StatefulBuilder(
            builder: (ctx, setPickerState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00142D),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFFC800),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.75),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/leaderboard_icons/back_design.png'),
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        Color(0xFF00142D),
                        BlendMode.modulate,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFC800).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.face_retouching_natural_rounded,
                              color: Color(0xFFFFC800),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHOOSE AVATAR',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '15 Garden Personas',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFC800).withValues(alpha: 0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              AudioService.instance.playClickSound();
                              Navigator.pop(dialogCtx);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Decorative Divider Line
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFC800).withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Action: Choose custom photo from device local storage
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          AudioService.instance.playClickSound();
                          final picked = await _pickImageFromStorage(context);
                          if (picked != null && dialogCtx.mounted) {
                            Navigator.pop(dialogCtx, picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002244).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Color(0xFF00E5FF),
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'CHOOSE FROM LOCAL STORAGE',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF00E5FF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Grid of 15 Avatars
                      Flexible(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: GameAvatarCatalog.avatars.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (ctx, index) {
                            final avatar = GameAvatarCatalog.avatars[index];
                            final isSelected = tempSelected == avatar.id ||
                                (tempSelected == null && index == 0);

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playClickSound();
                                setPickerState(() {
                                  tempSelected = avatar.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00305E).withValues(alpha: 0.85)
                                      : const Color(0xFF001834).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFFFFC800).withValues(alpha: 0.25),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        GameAvatarWidget(
                                          avatarIdOrUrl: avatar.id,
                                          size: 56,
                                          showBorder: true,
                                          isSelected: isSelected,
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF00E5FF),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0x66000000),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 13,
                                                color: Color(0xFF00152F),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      avatar.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CONFIRM AVATAR Button
                      Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF94C745),
                              Color(0xFF1E4A0F),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
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
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            AudioService.instance.playClickSound();
                            Navigator.pop(dialogCtx, tempSelected);
                          },
                          child: Text(
                            'CONFIRM AVATAR',
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Modal dialog allowing user to choose between 15 Game Avatars or device local storage / gallery
  Future<String?> _showChangePhotoOptions(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF00142D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFFC800),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.75),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/leaderboard_icons/back_design.png'),
                  fit: BoxFit.fill,
                  colorFilter: ColorFilter.mode(
                    Color(0xFF00142D),
                    BlendMode.modulate,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFC800).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              color: Color(0xFFFFC800),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CHANGE AVATAR',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          AudioService.instance.playClickSound();
                          Navigator.pop(dialogCtx);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFFFC800).withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Option 1: Choose from 15 Game Avatars
                  _buildPhotoOptionCard(
                    title: 'CHOOSE GAME AVATAR',
                    subtitle: 'Select from 15 custom botanical personas',
                    icon: Icons.face_retouching_natural_rounded,
                    accentColor: const Color(0xFFFFC800),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AudioService.instance.playClickSound();
                      Navigator.pop(dialogCtx, 'CHOOSE_CATALOG');
                    },
                  ),

                  const SizedBox(height: 12),

                  // Option 2: Choose from Local Storage / Gallery
                  _buildPhotoOptionCard(
                    title: 'CHOOSE FROM STORAGE',
                    subtitle: 'Pick custom photo from device gallery',
                    icon: Icons.photo_library_rounded,
                    accentColor: const Color(0xFF00E5FF),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AudioService.instance.playClickSound();
                      Navigator.pop(dialogCtx, 'CHOOSE_STORAGE');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Option card widget for avatar source selection
  Widget _buildPhotoOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF001E3D).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.3),
                      accentColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.chakraPetch(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks an image from local device storage / gallery and returns saved file path or uploaded URL
  Future<String?> _pickImageFromStorage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // 1. Copy to permanent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final ext = pickedFile.path.contains('.') ? pickedFile.path.split('.').last : 'jpg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // 2. If Firebase user is signed in, upload to Firebase Storage
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final storageRef = FirebaseStorage.instance
              .ref('user_avatars')
              .child('${currentUser.uid}.$ext');
          await storageRef.putFile(savedFile);
          final downloadUrl = await storageRef.getDownloadURL();
          return downloadUrl;
        }
      } catch (uploadError) {
        debugPrint('Firebase Storage upload note: $uploadError');
      }

      // Return local file path so it displays immediately and functions offline
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking image from local storage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
      return null;
    }
  }

  /// Text Field with distinct border pill, dark fill, and inline error feedback
  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF090420),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? const Color(0xFFFF3B30) : Colors.white,
              width: hasError ? 1.6 : 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
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
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF8080),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.chakraPetch(
                      color: const Color(0xFFFF8080),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);

    final user = authState.user;
    final progress = homeState.progress;

    final String defaultName;
    if (_nameController.text.trim().isNotEmpty) {
      defaultName = _nameController.text.trim();
    } else if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      defaultName = user.displayName!.trim();
    } else if (user?.email != null && user!.email!.contains('@')) {
      final prefix = user.email!.split('@').first.trim();
      if (prefix.toLowerCase().contains('adbhut')) {
        defaultName = 'Adbhut Keshav';
      } else {
        defaultName = prefix
            .replaceAll(RegExp(r'[._-]'), ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ')
            .trim();
      }
    } else {
      defaultName = 'Adbhut Keshav';
    }

    final email = (user?.email != null && user!.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : 'adbhutkeshav@gmail.com';

    final initialLetter = (defaultName.trim().isNotEmpty ? defaultName.trim()[0] : 'A').toUpperCase();

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
                              // 0. Circular Profile Avatar Icon
                              _buildProfileAvatar(
                                photoUrl: user?.photoUrl,
                                initialLetter: initialLetter,
                              ),

                              const SizedBox(height: 14),

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
                                iconAsset: 'assets/stats/flower.png',
                                fallbackIcon: Icons.local_florist_rounded,
                                iconColor: const Color(0xFFFF7BB0),
                                label: 'FLOWERS COLLECTED',
                                value: _formatNumber(flowers),
                              ),

                              const SizedBox(height: 14),

                              // 5. Box 2: HIGHEST SCORE
                              _buildStatBox(
                                iconAsset: 'assets/stats/score.png',
                                fallbackIcon: Icons.emoji_events_rounded,
                                iconColor: const Color(0xFFFFC800),
                                label: 'HIGHEST SCORE',
                                value: _formatNumber(highScore),
                              ),

                              const SizedBox(height: 14),

                              // 6. Box 3: LEVEL COMPLETED
                              _buildStatBox(
                                iconAsset: 'assets/stats/star.png',
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
            width: 28,
            height: 28,
            child: iconAsset != null
                ? (iconAsset.endsWith('.svg')
                    ? SvgPicture.asset(
                        iconAsset,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Icon(
                          fallbackIcon,
                          color: iconColor,
                          size: 26,
                        ),
                      )
                    : Image.asset(
                        iconAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          fallbackIcon,
                          color: iconColor,
                          size: 26,
                        ),
                      ))
                : Icon(
                    fallbackIcon,
                    color: iconColor,
                    size: 28,
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

  /// Circular Profile Avatar Icon with Elegant Gold Trim, Glow, and Initial / Photo
  Widget _buildProfileAvatar({
    required String? photoUrl,
    required String initialLetter,
    double size = 78,
  }) {
    return GameAvatarWidget(
      avatarIdOrUrl: photoUrl,
      fallbackLetter: initialLetter,
      size: size,
      showBorder: true,
    );
  }
}
