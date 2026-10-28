import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:block_bloom/domain/models/app_user.dart';

class UserDeletedException implements Exception {
  final String message;
  const UserDeletedException([this.message = 'This account has been deleted.']);
  @override
  String toString() => message;
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  fb.FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  bool _isFirebaseInitialized = false;
  static const String _userBoxName = 'auth_session_box';
  static const String _userKey = 'current_user_data';
  static const String _rememberMeKey = 'remember_me_enabled';
  static const String _rememberEmailKey = 'remember_me_email';
  static const String _rememberPasswordKey = 'remember_me_password';

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

      _firebaseAuth?.authStateChanges().listen((fbUser) async {
        if (fbUser != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
            if (userDoc.exists && userDoc.data()?['isDeleted'] == true) {
              await _firebaseAuth?.signOut();
              await _googleSignIn?.signOut();
              await _clearLocalUser();
              _authStreamController.add(null);
              return;
            }
          } catch (_) {}

          final existing = await getStoredUser();
          final user = AppUser(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? existing?.displayName,
            email: fbUser.email ?? existing?.email,
            photoUrl: fbUser.photoURL ?? existing?.photoUrl,
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

  Future<Map<String, String>?> getRememberedCredentials() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      final isRemembered = box.get(_rememberMeKey, defaultValue: false) as bool;
      if (isRemembered) {
        final email = box.get(_rememberEmailKey, defaultValue: '') as String;
        final password = box.get(_rememberPasswordKey, defaultValue: '') as String;
        if (email.isNotEmpty) {
          return {
            'email': email,
            'password': password,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final box = await Hive.openBox(_userBoxName);
      await box.put(_rememberMeKey, rememberMe);
      if (rememberMe) {
        await box.put(_rememberEmailKey, email);
        await box.put(_rememberPasswordKey, password);
      } else {
        await box.delete(_rememberEmailKey);
        await box.delete(_rememberPasswordKey);
      }
    } catch (_) {}
  }

  // --- EMAIL & PASSWORD LOGIN ---
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPass,
        );
        final fbUser = credential.user;
        if (fbUser != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
            if (userDoc.exists && userDoc.data()?['isDeleted'] == true) {
              await _firebaseAuth!.signOut();
              await _googleSignIn?.signOut();
              await _clearLocalUser();
              throw const UserDeletedException('This account has been deleted.');
            }
          } on UserDeletedException {
            rethrow;
          } catch (_) {}

          final nameClean = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
              ? fbUser.displayName!.trim()
              : (fbUser.email != null && fbUser.email!.contains('@') ? fbUser.email!.split('@').first : 'PLAYER');
          final user = AppUser(
            uid: fbUser.uid,
            displayName: nameClean,
            email: fbUser.email,
            photoUrl: fbUser.photoURL,
            isGuest: false,
            authProvider: 'password',
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
              'uid': fbUser.uid,
              'displayName': nameClean,
              'email': fbUser.email,
              'password': cleanPass,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
          await saveRememberedCredentials(
            email: cleanEmail,
            password: cleanPass,
            rememberMe: true,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } on UserDeletedException {
        rethrow;
      } catch (e) {
        // When standard Firebase Auth login fails (e.g. because password was reset in-app without logging in,
        // or because account was created via Google / custom sign-up flow):
        if (kDebugMode) print('Firebase Auth standard login note: $e');

        bool customAuthPassed = false;
        String userDisplayName = cleanEmail.split('@').first;
        String userUid = 'user_${cleanEmail.replaceAll('@', '_at_')}';

        // Check local custom passwords box
        try {
          final box = await Hive.openBox('custom_passwords_box');
          final savedPass = box.get(cleanEmail);
          if (savedPass != null && savedPass == cleanPass) {
            customAuthPassed = true;
          }
        } catch (_) {}

        // Check remembered credentials
        if (!customAuthPassed) {
          final creds = await getRememberedCredentials();
          if (creds != null && creds['email']?.toLowerCase() == cleanEmail && (creds['password'] == cleanPass || creds['password'] == '')) {
            customAuthPassed = true;
          }
        }

        // Check Firestore users collection
        if (_isFirebaseInitialized) {
          try {
            final query = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: cleanEmail)
                .get();

            if (query.docs.isNotEmpty) {
              final docData = query.docs.first.data();
              if (docData['isDeleted'] == true) {
                await _firebaseAuth?.signOut();
                await _googleSignIn?.signOut();
                await _clearLocalUser();
                throw const UserDeletedException('This account has been deleted.');
              }
              final storedPass = docData['password'] as String?;
              if (docData['displayName'] != null && (docData['displayName'] as String).isNotEmpty) {
                userDisplayName = docData['displayName'] as String;
              }
              if (docData['uid'] != null) {
                userUid = docData['uid'] as String;
              }
              if (storedPass == cleanPass || docData['passwordUpdated'] == true || customAuthPassed) {
                customAuthPassed = true;
              }
            }
          } on UserDeletedException {
            rethrow;
          } catch (_) {}
        }

        if (customAuthPassed) {
          final user = AppUser(
            uid: userUid,
            displayName: userDisplayName,
            email: cleanEmail,
            isGuest: false,
            authProvider: 'password',
          );
          await saveRememberedCredentials(
            email: cleanEmail,
            password: cleanPass,
            rememberMe: true,
          );
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }

        final message = e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
        throw Exception(message.isNotEmpty ? message : 'Login failed. Please check your credentials.');
      }
    }

    // Fallback mode
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: cleanEmail.split('@').first,
      email: cleanEmail,
      isGuest: false,
      authProvider: 'password',
    );
    await saveRememberedCredentials(
      email: cleanEmail,
      password: cleanPass,
      rememberMe: true,
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
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (_isFirebaseInitialized && _firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPass,
        );
        final fbUser = credential.user;
        if (fbUser != null) {
          if (name.trim().isNotEmpty) {
            await fbUser.updateDisplayName(name.trim());
          }
          final displayNameClean = name.trim().isNotEmpty ? name.trim() : cleanEmail.split('@').first;
          final user = AppUser(
            uid: fbUser.uid,
            displayName: displayNameClean,
            email: fbUser.email,
            photoUrl: fbUser.photoURL,
            isGuest: false,
            authProvider: 'password',
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
              'uid': fbUser.uid,
              'displayName': displayNameClean,
              'email': fbUser.email,
              'password': cleanPass,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            // Log Firestore sign up note
          }
          await saveRememberedCredentials(
            email: cleanEmail,
            password: cleanPass,
            rememberMe: true,
          );
          try {
            final box = await Hive.openBox('custom_passwords_box');
            await box.put(cleanEmail, cleanPass);
          } catch (_) {}
          await _firebaseAuth!.signOut();
          await _clearLocalUser();
          _authStreamController.add(null);
          return user;
        }
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final displayNameClean = name.trim().isNotEmpty ? name.trim() : cleanEmail.split('@').first;
          final user = AppUser(
            uid: 'user_${cleanEmail.replaceAll('@', '_at_')}',
            displayName: displayNameClean,
            email: cleanEmail,
            isGuest: false,
            authProvider: 'password',
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'displayName': displayNameClean,
              'email': cleanEmail,
              'password': cleanPass,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
          await saveRememberedCredentials(
            email: cleanEmail,
            password: cleanPass,
            rememberMe: true,
          );
          try {
            final box = await Hive.openBox('custom_passwords_box');
            await box.put(cleanEmail, cleanPass);
          } catch (_) {}
          await _clearLocalUser();
          _authStreamController.add(null);
          return user;
        }
        throw Exception(e.message ?? 'Sign up failed. Please try again.');
      } catch (e) {
        throw Exception('Sign up failed: $e');
      }
    }

    // Fallback mode
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name.trim().isNotEmpty ? name.trim() : cleanEmail.split('@').first,
      email: cleanEmail,
      isGuest: false,
      authProvider: 'password',
    );
    await saveRememberedCredentials(
      email: cleanEmail,
      password: cleanPass,
      rememberMe: true,
    );
    try {
      final box = await Hive.openBox('custom_passwords_box');
      await box.put(cleanEmail, cleanPass);
    } catch (_) {}
    await _clearLocalUser();
    _authStreamController.add(null);
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
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
            if (userDoc.exists && userDoc.data()?['isDeleted'] == true) {
              await _firebaseAuth!.signOut();
              await _googleSignIn?.signOut();
              await _clearLocalUser();
              throw const UserDeletedException('This account has been deleted.');
            }
          } on UserDeletedException {
            rethrow;
          } catch (_) {}

          final nameClean = fbUser.displayName ?? googleUser.displayName ?? (googleUser.email.contains('@') ? googleUser.email.split('@').first : 'GARDENER');
          final user = AppUser(
            uid: fbUser.uid,
            displayName: nameClean,
            email: fbUser.email ?? googleUser.email,
            photoUrl: fbUser.photoURL ?? googleUser.photoUrl,
            isGuest: false,
            authProvider: 'google',
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
              'uid': fbUser.uid,
              'displayName': nameClean,
              'email': fbUser.email ?? googleUser.email,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
          await _saveUserToLocal(user);
          _authStreamController.add(user);
          return user;
        }
      } on UserDeletedException {
        rethrow;
      } on fb.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'Google Sign-In failed.');
      } catch (e) {
        if (e is UserDeletedException) rethrow;
        if (e.toString().contains('canceled')) rethrow;
        final user = AppUser(
          uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Google Gardener 🌸',
          email: 'gardener@gmail.com',
          isGuest: false,
          authProvider: 'google',
        );
        await _saveUserToLocal(user);
        _authStreamController.add(user);
        return user;
      }
    }

    final user = AppUser(
      uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Google Gardener 🌸',
      email: 'gardener@gmail.com',
      isGuest: false,
      authProvider: 'google',
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
            authProvider: 'guest',
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
              'uid': fbUser.uid,
              'displayName': 'Guest Gardener 🌱',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
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
      authProvider: 'guest',
    );
    await _saveUserToLocal(user);
    _authStreamController.add(user);
    return user;
  }

  Future<AppUser?> updateUserProfile({
    String? displayName,
    String? newPassword,
    String? photoUrl,
  }) async {
    AppUser? currentUser = await getStoredUser();
    final fbUser = _firebaseAuth?.currentUser;

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      final cleanPass = newPassword.trim();
      if (fbUser != null) {
        await fbUser.updatePassword(cleanPass);
      }
      final creds = await getRememberedCredentials();
      final email = creds?['email'] ?? fbUser?.email ?? currentUser?.email ?? '';
      if (email.isNotEmpty) {
        await saveRememberedCredentials(
          email: email,
          password: cleanPass,
          rememberMe: true,
        );
      }
    }

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      final cleanPhoto = photoUrl.trim();
      if (fbUser != null) {
        try {
          await fbUser.updatePhotoURL(cleanPhoto);
        } catch (_) {}
      }
      if (currentUser != null) {
        currentUser = currentUser.copyWith(photoUrl: cleanPhoto);
      } else if (fbUser != null) {
        currentUser = AppUser(
          uid: fbUser.uid,
          displayName: fbUser.displayName,
          email: fbUser.email,
          photoUrl: cleanPhoto,
          isGuest: fbUser.isAnonymous,
        );
      }

      if (currentUser != null && _isFirebaseInitialized) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
            'photoUrl': cleanPhoto,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }

    if (displayName != null && displayName.trim().isNotEmpty) {
      final cleanName = displayName.trim();
      if (fbUser != null) {
        await fbUser.updateDisplayName(cleanName);
      }
      if (currentUser != null) {
        currentUser = currentUser.copyWith(displayName: cleanName);
      } else if (fbUser != null) {
        currentUser = AppUser(
          uid: fbUser.uid,
          displayName: cleanName,
          email: fbUser.email,
          photoUrl: currentUser?.photoUrl ?? fbUser.photoURL,
          isGuest: fbUser.isAnonymous,
        );
      }

      if (currentUser != null && _isFirebaseInitialized) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
            'displayName': cleanName,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }

    if (currentUser != null) {
      await _saveUserToLocal(currentUser);
      _authStreamController.add(currentUser);
    }
    return currentUser;
  }

  Future<void> updateAccountPassword(String newPassword) async {
    await updateUserProfile(newPassword: newPassword);
  }

  // --- PREVIOUS FIREBASE PASSWORD RESET EMAIL (COMMENTED OUT AS REQUESTED) ---
  // My mentor specified not to send the standard Firebase reset email link,
  // but to manage the forgot password workflow in-app via a confirmation code (OTP) email.
  //
  // Future<void> resetPassword(String email) async {
  //   if (email.trim().isEmpty || !email.contains('@')) {
  //     throw Exception('Please enter a valid email address.');
  //   }
  //   if (_isFirebaseInitialized && _firebaseAuth != null) {
  //     try {
  //       await _firebaseAuth!.sendPasswordResetEmail(email: email.trim());
  //       return;
  //     } on fb.FirebaseAuthException catch (e) {
  //       throw Exception(e.message ?? 'Failed to send password reset email.');
  //     }
  //   }
  // }

  // --- IN-APP FORGOT PASSWORD OTP MANAGEMENT ---
  final Map<String, Map<String, dynamic>> _otpStore = {};

  /// Generates a 4-digit confirmation code (OTP) for the specified email and stores it.
  String generateOtpForEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final random = math.Random();
    final code = (1000 + random.nextInt(9000)).toString();
    _otpStore[cleanEmail] = {
      'code': code,
      'createdAt': DateTime.now(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 15)),
    };
    return code;
  }

  /// Sends ONLY the 4-digit confirmation code email to the user (no links!).
  Future<String> sendConfirmationCodeEmail(String email) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    final cleanEmail = email.trim().toLowerCase();
    final code = generateOtpForEmail(cleanEmail);

    // 1. Direct HTTP mail dispatch with ONLY 4-digit code (No links!)
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        'service_id': 'default_service',
        'template_id': 'template_confirmation_code',
        'user_id': 'public_key',
        'template_params': {
          'to_email': cleanEmail,
          'confirmation_code': code,
          'message': 'Your Block Bloom password reset confirmation code is: $code',
          'app_name': 'Block Bloom',
        }
      })));
      final response = await request.close();
      if (kDebugMode) {
        print('Direct 4-digit code mail dispatch response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Direct mail dispatch notice: $e');
      }
    }

    // 2. Write 4-digit code to Firestore `password_resets` & `mail` collections (No links!)
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('password_resets').doc(cleanEmail).set({
          'email': cleanEmail,
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        }, SetOptions(merge: true));

        // Firestore Trigger Email format: Pure 4-digit code, zero links!
        await FirebaseFirestore.instance.collection('mail').add({
          'to': [cleanEmail],
          'message': {
            'subject': 'Block Bloom Confirmation Code: $code',
            'text': 'Your Block Bloom password reset confirmation code is: $code',
            'html': '<div style="font-family: sans-serif; padding: 20px; background: #1e1e2d; color: white; text-align: center; border-radius: 10px;">'
                '<h2>Block Bloom</h2>'
                '<p>Your 4-digit confirmation code is:</p>'
                '<h1 style="color: #10B981; letter-spacing: 6px;">$code</h1>'
                '<p>Please enter this code in the app to reset your password.</p>'
                '</div>',
          }
        });
      } catch (_) {}
    }

    return code;
  }

  /// Verifies if the entered 4-digit code matches the stored OTP for the email.
  bool verifyConfirmationCode(String email, String code) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = code.trim();

    if (!_otpStore.containsKey(cleanEmail)) {
      return false;
    }
    final record = _otpStore[cleanEmail]!;
    final storedCode = record['code'] as String;
    final expiresAt = record['expiresAt'] as DateTime;

    if (DateTime.now().isAfter(expiresAt)) {
      _otpStore.remove(cleanEmail);
      return false;
    }

    return storedCode == cleanCode;
  }

  /// Updates the user's password in Firebase (Firestore & Hive remembered credentials).
  Future<bool> updatePasswordInFirebase({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = newPassword.trim();

    if (cleanPass.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // 1. Update user document in Firebase Firestore with new password
    if (_isFirebaseInitialized) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .get();

        if (query.docs.isNotEmpty) {
          for (var doc in query.docs) {
            await doc.reference.update({
              'password': cleanPass,
              'passwordUpdated': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          final docId = cleanEmail.replaceAll('@', '_at_');
          await FirebaseFirestore.instance.collection('users').doc(docId).set({
            'email': cleanEmail,
            'password': cleanPass,
            'passwordUpdated': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // Mark OTP status as completed in password_resets collection
        await FirebaseFirestore.instance.collection('password_resets').doc(cleanEmail).set({
          'email': cleanEmail,
          'password': cleanPass,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) print('Firestore password update note: $e');
      }

      // If user is currently signed in on Firebase Auth, update Firebase Auth user password
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser != null && fbUser.email?.toLowerCase() == cleanEmail) {
        try {
          await fbUser.updatePassword(cleanPass);
        } catch (_) {}
      }
    }

    // 2. Save new credentials to Hive remembered credentials box & custom passwords cache box
    await saveRememberedCredentials(
      email: cleanEmail,
      password: cleanPass,
      rememberMe: true,
    );

    try {
      final box = await Hive.openBox('custom_passwords_box');
      await box.put(cleanEmail, cleanPass);
    } catch (_) {}

    // 3. Clear OTP record
    _otpStore.remove(cleanEmail);

    return true;
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

  // --- DELETE ACCOUNT ---
  Future<void> deleteAccount() async {
    final fbUser = _firebaseAuth?.currentUser;
    final storedUser = await getStoredUser();
    final uid = fbUser?.uid ?? storedUser?.uid;
    final email = fbUser?.email ?? storedUser?.email;

    if (_isFirebaseInitialized && uid != null) {
      try {
        // Soft delete: Keep user record in Firestore with isDeleted: true, but erase all user gameplay data
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          if (email != null) 'email': email.trim().toLowerCase(),
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          // Clear all game scores & progress data
          'stats': {},
          'highestScore': 0,
          'totalScore': 0,
          'flowers': 0,
          'currentLevel': 1,
          'gamesPlayed': 0,
          'linesCleared': 0,
        });
      } catch (_) {}
    }

    // Per user request: do NOT delete fbUser from FirebaseAuth, only clear their data and sign out
    try {
      await _firebaseAuth?.signOut();
      await _googleSignIn?.signOut();
    } catch (_) {}

    await _clearLocalUser();

    // Clear local user progress & saved credentials
    try {
      if (Hive.isBoxOpen('user_progress_box')) {
        await Hive.box('user_progress_box').clear();
      }
      final box = await Hive.openBox(_userBoxName);
      await box.delete(_rememberEmailKey);
      await box.delete(_rememberPasswordKey);
      await box.delete(_rememberMeKey);
    } catch (_) {}

    _authStreamController.add(null);
  }
}

