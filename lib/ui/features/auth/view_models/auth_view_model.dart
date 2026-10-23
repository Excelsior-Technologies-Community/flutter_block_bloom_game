import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/data/services/auth_service.dart';
import 'package:block_bloom/domain/models/app_user.dart';

class AuthViewModelState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthViewModelState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthViewModelState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isInitialized,
  }) {
    return AuthViewModelState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthViewModelState> {
  final AuthService _authService;

  AuthViewModel(this._authService) : super(const AuthViewModelState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    await _authService.init();

    final user = await _authService.getStoredUser();
    state = state.copyWith(
      user: user,
      clearUser: user == null,
      isLoading: false,
      isInitialized: true,
    );

    _authService.authStateChanges.listen((user) {
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isLoading: false,
        isInitialized: true,
      );
    });
  }

  Future<Map<String, String>?> getRememberedCredentials() async {
    return await _authService.getRememberedCredentials();
  }

  Future<bool> loginWithEmail(String email, String password, {bool rememberMe = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _authService.saveRememberedCredentials(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on UserDeletedException {
      state = state.copyWith(isLoading: false, error: 'ACCOUNT_DELETED');
      return false;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name, {bool rememberMe = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      await _authService.saveRememberedCredentials(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = state.copyWith(clearUser: true, isLoading: false);
      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on UserDeletedException {
      state = state.copyWith(isLoading: false, error: 'ACCOUNT_DELETED');
      return false;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      if (!message.contains('canceled')) {
        state = state.copyWith(isLoading: false, error: message);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInAsGuest();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  // --- COMMENTED OUT: PREVIOUS FIREBASE PASSWORD RESET EMAIL METHOD ---
  // Replaced with custom in-app confirmation code (OTP) workflow.
  //
  // Future<bool> sendPasswordReset(String email) async {
  //   state = state.copyWith(isLoading: true, clearError: true);
  //   try {
  //     await _authService.resetPassword(email);
  //     state = state.copyWith(isLoading: false);
  //     return true;
  //   } catch (e) {
  //     final message = e.toString().replaceAll('Exception: ', '');
  //     state = state.copyWith(isLoading: false, error: message);
  //     return false;
  //   }
  // }

  // --- CUSTOM IN-APP FORGOT PASSWORD WORKFLOW ---

  /// Generates and sends a 4-digit confirmation code email to the specified address.
  Future<String?> sendConfirmationCode(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = await _authService.sendConfirmationCodeEmail(email);
      state = state.copyWith(isLoading: false);
      return code;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return null;
    }
  }

  /// Verifies if the entered 4-digit confirmation code is correct.
  bool verifyConfirmationCode(String email, String code) {
    final isValid = _authService.verifyConfirmationCode(email, code);
    if (!isValid) {
      state = state.copyWith(error: 'Invalid or expired confirmation code. Please try again.');
    } else {
      state = state.copyWith(clearError: true);
    }
    return isValid;
  }

  /// Updates the user's password in Firebase and local storage.
  Future<bool> updatePasswordInFirebase(String email, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authService.updatePasswordInFirebase(
        email: email,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = state.copyWith(clearUser: true, isLoading: false);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await _authService.deleteAccount();
    state = state.copyWith(clearUser: true, isLoading: false);
  }

  Future<bool> updateUserProfile({String? displayName, String? newPassword}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _authService.updateUserProfile(
        displayName: displayName,
        newPassword: newPassword,
      );
      state = state.copyWith(user: updatedUser ?? state.user, isLoading: false);
      return true;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
