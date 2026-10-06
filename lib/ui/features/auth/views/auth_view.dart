import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/glossy_game_button.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
import 'package:block_bloom/ui/features/home/views/home_view.dart';
import 'package:block_bloom/ui/providers.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  bool _isSignUp = false;
  bool _isForgotPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final creds = await ref.read(authViewModelProvider.notifier).getRememberedCredentials();
    if (creds != null && mounted) {
      setState(() {
        _emailController.text = creds['email'] ?? '';
        _passwordController.text = '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _onSuccessNavigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    AudioService.instance.playClickSound();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authVm = ref.read(authViewModelProvider.notifier);

    if (_isSignUp) {
      final success = await authVm.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        rememberMe: _rememberMe,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in to continue.'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() {
            _emailController.clear();
            _passwordController.clear();
            _nameController.clear();
            _confirmPasswordController.clear();
            _isSignUp = false;
          });
        }
      }
    } else {
      final success = await authVm.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );
      if (success) _onSuccessNavigate();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    AudioService.instance.playClickSound();
    final authVm = ref.read(authViewModelProvider.notifier);
    final success = await authVm.loginWithGoogle();
    if (success) _onSuccessNavigate();
  }

  Future<void> _handleGuestLogin() async {
    FocusScope.of(context).unfocus();
    AudioService.instance.playClickSound();
    final authVm = ref.read(authViewModelProvider.notifier);
    final success = await authVm.loginAsGuest();
    if (success) _onSuccessNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001C),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF05001C),
              ),
            ),
          ),

          // Gradient Overlay for deep contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),

          // Main Foreground Form Content
          SafeArea(
            child: _isForgotPassword ? _buildForgotPasswordView() : _buildAuthForm(),
          ),
        ],
      ),
    );
  }

  // --- FORGOT PASSWORD VIEW MATCHING FIGMA SPECS ---
  Widget _buildForgotPasswordView() {
    final authState = ref.watch(authViewModelProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 370),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Title: 🌸 FORGOT PASSWORD 🌸
              FloralHeaderTitle(
                title: 'FORGOT PASSWORD',
                fontSize: 26.0,
                flowerSize: 36.0,
                curveAmount: 12.0,
                verticalOffset: -16.0,
                letterSpacing: 1.2,
              ),

              const SizedBox(height: 36),

              // Email Input Field matching Figma Rectangle 49 Specs exactly:
              // Width: 353px, Height: 45px, Radius: 12px, Border: 1px #FFFFFF, Fill: #003675 20%
              Container(
                width: 353,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF003675).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Enter email',
                    hintStyle: GoogleFonts.chakraPetch(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Button: ENTER (Glossy Green Game Button)
              GreenGameButton(
                text: authState.isLoading ? 'SENDING...' : 'ENTER',
                width: 240,
                height: 50,
                fontSize: 20,
                borderRadius: 12,
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        final email = _forgotEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid email address.'),
                              backgroundColor: Color(0xFFFF3B30),
                            ),
                          );
                          return;
                        }
                        FocusScope.of(context).unfocus();
                        final authVm = ref.read(authViewModelProvider.notifier);
                        final sent = await authVm.sendPasswordReset(email);
                        if (sent && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent! Check your inbox.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          setState(() {
                            _isForgotPassword = false;
                            _forgotEmailController.clear();
                          });
                        }
                      },
              ),

              const SizedBox(height: 20),

              // Back Link: Underlined "Back" text with larger bold font
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AudioService.instance.playClickSound();
                  setState(() {
                    _isForgotPassword = false;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Back',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MAIN AUTH FORM (LOGIN / SIGN UP) ---
  Widget _buildAuthForm() {
    final authState = ref.watch(authViewModelProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 370),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Title
              FloralHeaderTitle(
                title: _isSignUp ? 'CREATE ACCOUNT' : 'WELCOME BACK',
                fontSize: 28.0,
                flowerSize: 38.0,
                curveAmount: 14.0,
                verticalOffset: -20.0,
                letterSpacing: 1.5,
              ),

              const SizedBox(height: 24),

              // Main Glassmorphic Auth Card Container (#001834)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF001834).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFFFC800),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Tab Switcher Bar: LOG IN | SIGN UP
                      _buildTabSwitcher(),

                      const SizedBox(height: 20),

                      // Error Message Display
                      if (authState.error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF420914),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF3B30),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF8080),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 2. Full Name Input (Sign Up mode only)
                      if (_isSignUp) ...[
                        _buildInputField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 3. Email Input
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // 4. Password Input
                      _buildInputField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFFFFC800),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // 5. Confirm Password Input (Sign Up mode only)
                      if (_isSignUp) ...[
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          icon: Icons.lock_clock_outlined,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: const Color(0xFFFFC800),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Remember Me Checkbox & Forgot Password Link
                      if (!_isSignUp) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFFFFC800),
                                      checkColor: const Color(0xFF001834),
                                      side: const BorderSide(color: Color(0xFFFFC800), width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember Me',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFFC800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playClickSound();
                                setState(() {
                                  _isForgotPassword = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFC800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                              const SizedBox(height: 20),

                              // 6. Action Button: LOG IN / SIGN UP
                              SizedBox(
                                width: double.infinity,
                                child: GlossyGameButton.play(
                                  text: authState.isLoading
                                      ? 'PLEASE WAIT...'
                                      : (_isSignUp ? 'SIGN UP' : 'LOG IN'),
                                  onPressed: authState.isLoading ? () {} : _submitForm,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 7. Divider: ◆ OR CONTINUE WITH ◆
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF103975),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '◆ OR ◆',
                                      style: GoogleFonts.chakraPetch(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFFC800),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF103975),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // 8. Google Sign-In Button
                              _buildGoogleSignInButton(),

                              const SizedBox(height: 14),

                              // 9. Play as Guest Link
                              GestureDetector(
                                onTap: _handleGuestLogin,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🌱 ', style: TextStyle(fontSize: 14)),
                                      Text(
                                        'Play as Guest',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2096E7),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF2096E7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  // Segmented Tab Switcher Bar: LOG IN | SIGN UP
  Widget _buildTabSwitcher() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF000F22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF103975),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // LOG IN Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignUp) {
                  HapticFeedback.selectionClick();
                  ref.read(authViewModelProvider.notifier).clearError();
                  setState(() {
                    _emailController.clear();
                    _passwordController.clear();
                    _nameController.clear();
                    _confirmPasswordController.clear();
                    _isSignUp = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isSignUp ? const Color(0xFFFFC800) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: !_isSignUp
                      ? [
                          const BoxShadow(
                            color: Color(0x66FFC800),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'LOG IN',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: !_isSignUp ? const Color(0xFF001834) : Colors.white60,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // SIGN UP Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignUp) {
                  HapticFeedback.selectionClick();
                  ref.read(authViewModelProvider.notifier).clearError();
                  setState(() {
                    _emailController.clear();
                    _passwordController.clear();
                    _nameController.clear();
                    _confirmPasswordController.clear();
                    _isSignUp = true;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isSignUp ? const Color(0xFFFFC800) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _isSignUp
                      ? [
                          const BoxShadow(
                            color: Color(0x66FFC800),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'SIGN UP',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _isSignUp ? const Color(0xFF001834) : Colors.white60,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Input Field Component
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.chakraPetch(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFFFFC800),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.chakraPetch(
          fontSize: 13,
          color: Colors.white38,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFFFC800), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF000B1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF103975), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFC800), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        errorStyle: GoogleFonts.chakraPetch(
          fontSize: 11,
          color: const Color(0xFFFF8080),
        ),
      ),
    );
  }

  // Google Sign-In Custom Button
  Widget _buildGoogleSignInButton() {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleSignIn,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLoading ? 0.7 : 1.0,
        child: Container(
          height: 46,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF000F22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFC800).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC800)),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google G Icon Badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Google',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
