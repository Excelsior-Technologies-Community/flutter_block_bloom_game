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

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
