import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_template_service.dart';
import 'notification_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  /// Web Client ID (serverClientId) from Firebase Console:
  /// Firebase Console -> Authentication -> Sign-in method -> Google -> Web SDK configuration -> Web client ID.
  /// Format: 658452739740-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
  static String serverClientId =
      '658452739740-kq5u65eirbt472jrcbapq43bq8g4gvmo.apps.googleusercontent.com';

  FirebaseAuth? _auth;
  bool _googleSignInInitialized = false;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhotoUrl = ''.obs;
  final RxString currentDeviceId = ''.obs;
  final RxString effectiveUid = ''.obs;
  final RxString guestUserName = 'Music Lover'.obs;

  String get effectiveUserName {
    if (isLoggedIn.value && userName.value.isNotEmpty) {
      return userName.value;
    }
    return guestUserName.value.isNotEmpty ? guestUserName.value : 'Guest';
  }

  @override
  void onInit() {
    super.onInit();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _auth = FirebaseAuth.instance;

      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
        );
        _googleSignInInitialized = true;
      } catch (gErr) {
        debugPrint('[AuthService] GoogleSignIn.initialize deferred or platform-handled: $gErr');
      }

      // Fetch device ID immediately
      final devInfo = await _getDeviceInfo();
      currentDeviceId.value = devInfo['deviceId'] ?? 'device_unknown';

      // Load cached profile data in case offline or starting up
      await _loadCachedProfile();

      _updateEffectiveUid();

      // Listen to Firebase Auth state
      _auth?.authStateChanges().listen((user) {
        _syncUserState(user);
      });

      // If user is not logged in, ensure guest device is tracked in Firestore 'users' collection
      if (_auth?.currentUser == null) {
        await _syncGuestDeviceToFirestore();
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase initialization skipped/fallback: $e');
      await _loadCachedProfile();
      _updateEffectiveUid();
    }
  }

  void _updateEffectiveUid() {
    if (currentUser.value != null) {
      effectiveUid.value = currentUser.value!.uid;
    } else {
      final devId = currentDeviceId.value.isNotEmpty ? currentDeviceId.value : 'guest_device';
      effectiveUid.value = 'device_$devId';
    }
  }

  Future<void> updateGuestName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    guestUserName.value = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_user_name', clean);
      await _syncGuestDeviceToFirestore();
    } catch (_) {}
  }

  Future<void> _syncGuestDeviceToFirestore() async {
    try {
      final devInfo = await _getDeviceInfo();
      final deviceId = devInfo['deviceId'] ?? currentDeviceId.value;
      if (deviceId.isEmpty || deviceId == 'unknown') return;

      final docId = 'device_$deviceId';
      final userDoc = FirebaseFirestore.instance.collection('users').doc(docId);

      final data = <String, dynamic>{
        'uid': docId,
        'deviceId': deviceId,
        'deviceModel': devInfo['deviceModel'] ?? 'unknown',
        'deviceBrand': devInfo['deviceBrand'] ?? 'unknown',
        'osVersion': devInfo['osVersion'] ?? 'unknown',
        'displayName': guestUserName.value,
        'email': '',
        'photoUrl': '',
        'isLoggedIn': false,
        'authType': 'guest',
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await userDoc.set(data, SetOptions(merge: true));

      // Sync FCM token for guest
      if (Get.isRegistered<NotificationService>()) {
        unawaited(NotificationService.to.syncTokenToFirestore());
      }
    } catch (e) {
      debugPrint('[AuthService] Error syncing guest device to Firestore: $e');
    }
  }

  static String formatCleanDisplayName({String? displayName, String? email}) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      final trimmed = displayName.trim();
      // If it doesn't look like an email or dot/underscore delimited username
      if (!trimmed.contains('@') && !trimmed.contains('.')) {
        return trimmed;
      }
    }

    final raw = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (email != null && email.contains('@') ? email.split('@').first : '');

    final lower = raw.toLowerCase();
    if (lower.contains('nikhil')) {
      return 'Nikhil';
    }

    final parts = raw.split(RegExp(r'[._\d]')).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      final first = parts.first;
      if (first.length > 1) {
        return first[0].toUpperCase() + first.substring(1).toLowerCase();
      }
    }

    return 'Nikhil';
  }

  void _syncUserState(User? user, {String source = 'app'}) {
    currentUser.value = user;
    if (user != null) {
      isLoggedIn.value = true;
      userName.value = formatCleanDisplayName(
        displayName: user.displayName,
        email: user.email,
      );
      userEmail.value = user.email ?? '';
      userPhotoUrl.value = user.photoURL ?? '';
      _updateEffectiveUid();
      _cacheProfile(userName.value, userEmail.value, userPhotoUrl.value);
      _syncUserToFirestore(user, source: source);
    } else {
      isLoggedIn.value = false;
      userName.value = '';
      userEmail.value = '';
      userPhotoUrl.value = '';
      _updateEffectiveUid();
      _syncGuestDeviceToFirestore();
    }
  }

  Future<void> _syncUserToFirestore(User user, {String source = 'app'}) async {
    try {
      final devInfo = await _getDeviceInfo();
      final deviceId = devInfo['deviceId'] ?? currentDeviceId.value;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final cleanName = formatCleanDisplayName(
        displayName: user.displayName,
        email: user.email,
      );

      // Check if user already exists to differentiate new vs returning login
      DocumentSnapshot<Map<String, dynamic>>? existingSnap;
      try {
        existingSnap = await userDoc.get().timeout(const Duration(seconds: 4));
      } catch (getErr) {
        debugPrint('[AuthService] Could not retrieve existing user doc: $getErr');
      }

      final isNewUser = existingSnap == null ||
          !existingSnap.exists ||
          existingSnap.data()?['createdAt'] == null;

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': cleanName,
        'photoUrl': user.photoURL ?? userPhotoUrl.value,
        'deviceId': deviceId,
        'deviceModel': devInfo['deviceModel'] ?? 'unknown',
        'deviceBrand': devInfo['deviceBrand'] ?? 'unknown',
        'osVersion': devInfo['osVersion'] ?? 'unknown',
        'isLoggedIn': true,
        'authType': 'google',
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isNewUser) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['welcomeEmailSent'] = true;
      } else {
        data['lastLoginAt'] = FieldValue.serverTimestamp();
      }

      await userDoc.set(data, SetOptions(merge: true));

      // Dispatch automated Welcome or Welcome Back Email via Brevo
      if (user.email != null && user.email!.contains('@')) {
        if (isNewUser) {
          unawaited(EmailTemplateService.sendWelcomeEmail(
            userId: user.uid,
            userEmail: user.email!,
            userName: cleanName,
            source: source,
          ));
        } else {
          // Send Welcome Back email if returning after at least 30 minutes
          final lastLoginTs = existingSnap.data()?['lastLoginAt'] as Timestamp?;
          final shouldSend = lastLoginTs == null ||
              DateTime.now().difference(lastLoginTs.toDate()).inMinutes >= 30;

          if (shouldSend) {
            unawaited(EmailTemplateService.sendWelcomeBackEmail(
              userId: user.uid,
              userEmail: user.email!,
              userName: cleanName,
              source: source,
            ));
          }
        }
      }

      // Also link the guest device record in 'users/device_{deviceId}' for unified dashboard tracking
      if (deviceId.isNotEmpty && deviceId != 'unknown') {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc('device_$deviceId')
              .set({
            'linkedUid': user.uid,
            'isLoggedIn': true,
            'authType': 'google',
            'email': user.email ?? '',
            'displayName': cleanName,
            'lastActive': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
      // Also sync current FCM token and topics to this authenticated user doc
      if (Get.isRegistered<NotificationService>()) {
        unawaited(NotificationService.to.syncTokenToFirestore());
      }
    } catch (e) {
      debugPrint('[AuthService] Error syncing user to Firestore: $e');
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final android = await plugin.androidInfo;
        return {
          'deviceId': android.id,
          'deviceModel': '${android.manufacturer} ${android.model}',
          'deviceBrand': android.brand,
          'osVersion': 'Android ${android.version.release} (SDK ${android.version.sdkInt})',
        };
      } else if (!kIsWeb && Platform.isIOS) {
        final ios = await plugin.iosInfo;
        return {
          'deviceId': ios.identifierForVendor ?? 'unknown',
          'deviceModel': ios.utsname.machine,
          'deviceBrand': 'Apple',
          'osVersion': 'iOS ${ios.systemVersion}',
        };
      }
    } catch (e) {
      debugPrint('[AuthService] Device info lookup failed: $e');
    }
    return {
      'deviceId': 'unknown',
      'deviceModel': 'unknown',
      'deviceBrand': 'unknown',
      'osVersion': 'unknown',
    };
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
      guestUserName.value = prefs.getString('guest_user_name') ?? 'Music Lover';
      final loggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      if (loggedIn) {
        userName.value = prefs.getString('auth_user_name') ?? 'Music Lover';
        userEmail.value = prefs.getString('auth_user_email') ?? '';
        userPhotoUrl.value = prefs.getString('auth_user_photo') ?? '';
        isLoggedIn.value = true;
      }
    } catch (_) {}
  }

  Future<bool> signInWithGoogle({String source = 'app'}) async {
    isLoading.value = true;
    try {
      if (!_googleSignInInitialized || serverClientId.isNotEmpty) {
        try {
          await GoogleSignIn.instance.initialize(
            serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
          );
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
        _syncUserState(user, source: source);
        isLoading.value = false;
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In error: $e');
      if (e.toString().contains('serverClientId must be provided') ||
          e.toString().contains('clientConfigurationError')) {
        Get.snackbar(
          'Google Sign-In Configuration Required',
          'Please provide the Web Client ID (serverClientId) from Firebase Console under Authentication > Sign-in method > Google.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
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
