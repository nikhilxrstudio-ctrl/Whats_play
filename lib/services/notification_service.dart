import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Message received: ${message.messageId} - ${message.notification?.title}');

  // If this is a data-only message (or background payload without notification body),
  // show it using AwesomeNotifications in the system drawer
  if (message.notification == null && (message.data['title'] != null || message.data['body'] != null)) {
    await NotificationService.showAwesomeNotification(
      title: message.data['title'] ?? 'WhatsPlay Music',
      body: message.data['body'] ?? '',
      imageUrl: message.data['imageUrl'],
      payload: message.data,
    );
  }
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final RxString fcmToken = ''.obs;
  final RxList<String> subscribedTopics = <String>[].obs;
  final RxBool hasPermission = false.obs;

  static const String _kSubscribedTopicsKey = 'fcm_subscribed_topics';
  static const String _kFcmTokenKey = 'fcm_device_token';
  static const String channelKey = 'whatsplay_alerts';
  static const String channelGroupKey = 'whatsplay_channel_group';

  // Base topics subscribed for all installs
  static const List<String> baseTopics = ['all_users', 'new_releases'];

  @override
  void onInit() {
    super.onInit();
    init();
  }

  /// Initialize FCM & AwesomeNotifications, request permissions, fetch token, and setup listeners
  Future<void> init() async {
    try {
      // 1. Initialize AwesomeNotifications for native device notifications
      await _initAwesomeNotifications();

      // 2. Request user permission
      await _requestPermission();

      // 3. Load cached topics & token
      await _loadCachedData();

      // 4. Fetch current FCM token
      await _initToken();

      // 5. Subscribe to baseline broadcast topics
      await _subscribeBaseTopics();

      // 6. Setup foreground & tap listeners
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('[NotificationService] Initialization warning: $e');
    }
  }

  Future<void> _initAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null, // Uses default application icon
        [
          NotificationChannel(
            channelGroupKey: channelGroupKey,
            channelKey: channelKey,
            channelName: 'WhatsPlay Alerts',
            channelDescription: 'Push notifications for music releases, updates, and blends',
            defaultColor: const Color(0xFF1DB954),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            playSound: true,
            criticalAlerts: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: channelGroupKey,
            channelGroupName: 'WhatsPlay Notifications Group',
          ),
        ],
        debug: false,
      );

      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // Listen to notification clicks on device
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
      );
    } catch (e) {
      debugPrint('[NotificationService] AwesomeNotifications init notice: $e');
    }
  }

  /// Action listener for AwesomeNotifications when user taps the notification
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('[AwesomeNotifications] Action received: ${receivedAction.payload}');
    final payload = receivedAction.payload;
    if (payload != null && payload.isNotEmpty) {
      handleNotificationClick(payload);
    }
  }

  /// Displays native Android device pop-up / notification panel alert via AwesomeNotifications
  static Future<void> showAwesomeNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final safePayload = payload?.map((k, v) => MapEntry(k, v.toString())) ?? <String, String>{};

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          bigPicture: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
          notificationLayout: (imageUrl != null && imageUrl.isNotEmpty)
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
          payload: safePayload,
          wakeUpScreen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
    } catch (e) {
      debugPrint('[AwesomeNotifications] Show notification error: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      hasPermission.value =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('[NotificationService] FCM notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[NotificationService] Error requesting notification permission: $e');
    }
  }

  Future<void> _initToken() async {
    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kFcmTokenKey, token);
        debugPrint('[NotificationService] FCM Token fetched: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

        await syncTokenToFirestore(token);
      }

      // Listen for token refresh events
      // ignore: deprecated_member_use
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[NotificationService] FCM Token refreshed: $newToken');
        fcmToken.value = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kFcmTokenKey, newToken);
        await syncTokenToFirestore(newToken);
      });
    } catch (e) {
      debugPrint('[NotificationService] Error retrieving FCM token: $e');
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_kFcmTokenKey);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        fcmToken.value = cachedToken;
      }

      final cachedList = prefs.getStringList(_kSubscribedTopicsKey) ?? [];
      subscribedTopics.assignAll(cachedList);
    } catch (_) {}
  }

  Future<void> _subscribeBaseTopics() async {
    for (final topic in baseTopics) {
      if (!subscribedTopics.contains(topic)) {
        await subscribeToTopic(topic);
      }
    }
  }

  /// Normalizes human genre strings to valid FCM topic identifiers
  /// Format requirement: [a-zA-Z0-9-_.~%]{1,900}
  static String normalizeGenreTopic(String genre) {
    final clean = genre
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('/', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    return 'genre_$clean';
  }

  /// Synchronize genre preferences from Onboarding or Settings to FCM topics
  Future<void> syncGenreTopicSubscriptions(List<String> selectedGenres) async {
    final targetGenreTopics = selectedGenres.map(normalizeGenreTopic).toSet();

    // Find previous genre topics that user unselected
    final currentGenreTopics = subscribedTopics
        .where((t) => t.startsWith('genre_'))
        .toSet();

    final toUnsubscribe = currentGenreTopics.difference(targetGenreTopics);
    final toSubscribe = targetGenreTopics.difference(currentGenreTopics);

    // Unsubscribe from removed topics
    for (final topic in toUnsubscribe) {
      await unsubscribeFromTopic(topic);
    }

    // Subscribe to newly added topics
    for (final topic in toSubscribe) {
      await subscribeToTopic(topic);
    }

    // Save list and sync to Firestore
    await _persistSubscribedTopics();
  }

  /// Subscribe to a specific FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      final cleanTopic = topic.trim();
      if (cleanTopic.isEmpty) return;

      await _messaging.subscribeToTopic(cleanTopic);
      if (!subscribedTopics.contains(cleanTopic)) {
        subscribedTopics.add(cleanTopic);
      }
      debugPrint('[NotificationService] Subscribed to topic: $cleanTopic');
      await _persistSubscribedTopics();
    } catch (e) {
      debugPrint('[NotificationService] Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final cleanTopic = topic.trim();
      if (cleanTopic.isEmpty) return;

      await _messaging.unsubscribeFromTopic(cleanTopic);
      subscribedTopics.remove(cleanTopic);
      debugPrint('[NotificationService] Unsubscribed from topic: $cleanTopic');
      await _persistSubscribedTopics();
    } catch (e) {
      debugPrint('[NotificationService] Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> _persistSubscribedTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSubscribedTopicsKey, subscribedTopics.toList());
      await syncTopicsToFirestore();
    } catch (_) {}
  }

  /// Sync FCM token to the user's document in Firestore
  Future<void> syncTokenToFirestore([String? token]) async {
    final currentToken = token ?? fcmToken.value;
    if (currentToken.isEmpty) return;

    try {
      final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
      final uid = auth?.currentUser.value?.uid;
      final deviceId = auth?.currentDeviceId.value;

      final data = <String, dynamic>{
        'fcmToken': currentToken,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
        'subscribedTopics': subscribedTopics.toList(),
      };

      // 1. If logged in, update users/{uid}
      if (uid != null && uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }

      // 2. Also keep guest / device record updated at users/device_{deviceId}
      if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc('device_$deviceId')
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[NotificationService] Error syncing FCM token to Firestore: $e');
    }
  }

  /// Sync topic subscriptions to Firestore
  Future<void> syncTopicsToFirestore() async {
    try {
      final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
      final uid = auth?.currentUser.value?.uid;
      final deviceId = auth?.currentDeviceId.value;

      final data = <String, dynamic>{
        'subscribedTopics': subscribedTopics.toList(),
        'topicsUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (uid != null && uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }

      if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc('device_$deviceId')
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[NotificationService] Error syncing topics to Firestore: $e');
    }
  }

  /// Setup foreground message listener and notification tap handler
  void _setupMessageHandlers() {
    // 1. Foreground message handling - Displays native Android heads-up popup via AwesomeNotifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}');

      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'WhatsPlay Music';
      final body = notification?.body ?? message.data['body'] ?? '';
      final imageUrl = notification?.android?.imageUrl ?? message.data['imageUrl'];

      if (title.isNotEmpty || body.isNotEmpty) {
        showAwesomeNotification(
          title: title,
          body: body,
          imageUrl: imageUrl,
          payload: message.data,
        );
      }
    });

    // 2. App opened from background state via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification clicked (background): ${message.data}');
      handleNotificationClick(message.data);
    });

    // 3. App opened from terminated / killed state via notification tap
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('[FCM] App launched from terminated state via notification: ${message.data}');
        handleNotificationClick(message.data);
      }
    });
  }

  static void handleNotificationClick(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    // Handle deep link route or blend code
    final route = data['route'] as String?;
    final blendCode = data['blendCode'] as String?;

    if (blendCode != null && blendCode.isNotEmpty) {
      debugPrint('[NotificationService] Navigating to Blend: $blendCode');
      Get.toNamed('/blend', arguments: {'code': blendCode});
      return;
    }

    if (route != null && route.isNotEmpty) {
      debugPrint('[NotificationService] Navigating to route: $route');
      Get.toNamed(route);
    }
  }
}
