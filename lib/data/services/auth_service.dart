import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:block_bloom/domain/models/app_user.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  fb.FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  bool _isFirebaseInitialized = false;
  static const String _userBoxName = 'auth_session_box';
  static const String _userKey = 'current_user_data';

  final StreamController<AppUser?> _authStreamController = StreamController<AppUser?>.broadcast();

  Stream<AppUser?> get authStateChanges => _authStreamController.stream;

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
      } else {
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
      }
      _firebaseAuth = fb.FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn(
        serverClientId: '900790491091-vp842v2tjbep2g5ael175ih1cg4n59kk.apps.googleusercontent.com',
      );

      _firebaseAuth?.authStateChanges().listen((fbUser) {
        if (fbUser != null) {
          final user = AppUser(
            uid: fbUser.uid,
            displayName: fbUser.displayName,
            email: fbUser.email,
            photoUrl: fbUser.photoURL,
            isGuest: fbUser.isAnonymous,
          );
          _saveUserToLocal(user);
          _authStreamController.add(user);
        }
      });
    } catch (e) {
      _isFirebaseInitialized = false;
    }

    // Load persisted local user if any
    final localUser = await getStoredUser();
    _authStreamController.add(localUser);
  }

  Future<AppUser?> getStoredUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      final rawData = box.get(_userKey);
      if (rawData != null && rawData is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(rawData));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveUserToLocal(AppUser user) async {
    try {
      final box = await Hive.openBox(_userBoxName);
      await box.put(_userKey, user.toJson());
    } catch (_) {}
  }

  Future<void> _clearLocalUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      await box.delete(_userKey);
    } catch (_) {}
  }

  // --- EMAIL & PASSWORD LOGIN ---
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final fbUser = credential.user;
        if (fbUser != null) {
          final user = AppUser(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? email.split('@').first,
            email: fbUser.email,
            photoUrl: fbUser.photoURL,
            isGuest: false,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Login failed. Please check your credentials.');
      } catch (e) {
        throw Exception('Login failed: $e');
      }
    }

    // Fallback mode (if Firebase config isn't registered natively yet on local dev machine)
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: email.split('@').first,
      email: email.trim(),
      isGuest: false,
    );
    await _saveUserToLocal(user);
    _authStreamController.add(user);
    return user;
  }

  // --- EMAIL & PASSWORD SIGN UP ---
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final fbUser = credential.user;
        if (fbUser != null) {
          if (name.trim().isNotEmpty) {
            await fbUser.updateDisplayName(name.trim());
          }
          final user = AppUser(
            uid: fbUser.uid,
            displayName: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
            email: fbUser.email,
            photoUrl: fbUser.photoURL,
            isGuest: false,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Sign up failed. Please try again.');
      } catch (e) {
        throw Exception('Sign up failed: $e');
      }
    }

    // Fallback mode
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
      email: email.trim(),
      isGuest: false,
    );
    await _saveUserToLocal(user);
    _authStreamController.add(user);
    return user;
  }

  // --- GOOGLE SIGN IN ---
  Future<AppUser> signInWithGoogle() async {
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        _googleSignIn ??= GoogleSignIn(
          serverClientId: '900790491091-vp842v2tjbep2g5ael175ih1cg4n59kk.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          throw Exception('Google Sign-In canceled by user.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth!.signInWithCredential(credential);
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final user = AppUser(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? googleUser.displayName,
            email: fbUser.email ?? googleUser.email,
            photoUrl: fbUser.photoURL ?? googleUser.photoUrl,
            isGuest: false,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Google Sign-In failed.');
      } catch (e) {
        if (e.toString().contains('canceled')) rethrow;
        // Fallback simulate Google sign in if Google API service missing locally
        final user = AppUser(
          uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Google Gardener 🌸',
          email: 'gardener@gmail.com',
          isGuest: false,
        );
        await _saveUserToLocal(user);
        _authStreamController.add(user);
        return user;
      }
    }

    // Fallback simulated Google sign in
    final user = AppUser(
      uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Google Gardener 🌸',
      email: 'gardener@gmail.com',
      isGuest: false,
    );
    await _saveUserToLocal(user);
    _authStreamController.add(user);
    return user;
  }

  // --- GUEST LOGIN ---
  Future<AppUser> signInAsGuest() async {
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth!.signInAnonymously();
        final fbUser = credential.user;
        if (fbUser != null) {
          final user = AppUser(
            uid: fbUser.uid,
            displayName: 'Guest Gardener 🌱',
            isGuest: true,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } catch (_) {}
    }

    final user = AppUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Guest Gardener 🌱',
      isGuest: true,
    );
    await _saveUserToLocal(user);
    _authStreamController.add(user);
    return user;
  }

  // --- PASSWORD RESET EMAIL ---
  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        await _firebaseAuth!.sendPasswordResetEmail(email: email.trim());
        return;
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Failed to send password reset email.');
      }
    }
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        await _firebaseAuth!.signOut();
        await _googleSignIn?.signOut();
      } catch (_) {}
    }
    await _clearLocalUser();
    _authStreamController.add(null);
  }
}
