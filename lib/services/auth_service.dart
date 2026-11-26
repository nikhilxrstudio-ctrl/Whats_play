import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  FirebaseAuth? _auth;
  bool _googleSignInInitialized = false;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhotoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _auth = FirebaseAuth.instance;

      try {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      } catch (gErr) {
        debugPrint('[AuthService] GoogleSignIn.initialize deferred or platform-handled: $gErr');
      }

      // Listen to Firebase Auth state
      _auth?.authStateChanges().listen((user) {
        _syncUserState(user);
      });

      // Load cached profile data in case offline or starting up
      await _loadCachedProfile();
    } catch (e) {
      debugPrint('[AuthService] Firebase initialization skipped/fallback: $e');
      await _loadCachedProfile();
    }
  }

  void _syncUserState(User? user) {
    currentUser.value = user;
    if (user != null) {
      isLoggedIn.value = true;
      userName.value = user.displayName ?? (user.email?.split('@').first ?? 'Music Lover');
      userEmail.value = user.email ?? '';
      userPhotoUrl.value = user.photoURL ?? '';
      _cacheProfile(userName.value, userEmail.value, userPhotoUrl.value);
    } else {
      isLoggedIn.value = false;
      userName.value = '';
      userEmail.value = '';
      userPhotoUrl.value = '';
    }
  }

  Future<void> _cacheProfile(String name, String email, String photo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_name', name);
      await prefs.setString('auth_user_email', email);
      await prefs.setString('auth_user_photo', photo);
      await prefs.setBool('auth_is_logged_in', true);
    } catch (_) {}
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      if (loggedIn) {
        userName.value = prefs.getString('auth_user_name') ?? 'Music Lover';
        userEmail.value = prefs.getString('auth_user_email') ?? '';
        userPhotoUrl.value = prefs.getString('auth_user_photo') ?? '';
        isLoggedIn.value = true;
      }
    } catch (_) {}
  }

  Future<bool> signInWithGoogle() async {
    isLoading.value = true;
    try {
      if (!_googleSignInInitialized) {
        try {
          await GoogleSignIn.instance.initialize();
          _googleSignInInitialized = true;
        } catch (_) {}
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication authTokens = account.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: authTokens.idToken,
      );

      _auth ??= FirebaseAuth.instance;
      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        _syncUserState(user);
        isLoading.value = false;
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In error: $e');
    }
    isLoading.value = false;
    return false;
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await GoogleSignIn.instance.signOut();
      await _auth?.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_user_photo');
      await prefs.setBool('auth_is_logged_in', false);
      _syncUserState(null);
    } catch (e) {
      debugPrint('[AuthService] Sign-Out error: $e');
    }
    isLoading.value = false;
  }
}
