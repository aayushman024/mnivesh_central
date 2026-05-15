import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../Managers/AuthManager.dart';


// needs to be top-level, isolate spins up without UI context
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("bg message rx: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // static Future<void> _handlePayload(Map<String, dynamic> data) async {
  //   // wait until the root navigator is ready (important for cold starts)
  //   final navigatorKey = SnackbarService.navigatorKey;
  //   int retries = 0;
  //   while (navigatorKey.currentState == null && retries < 20) {
  //     await Future.delayed(const Duration(milliseconds: 200));
  //     retries++;
  //   }
  //
  //   final context = navigatorKey.currentState?.context;
  //   if (context != null && context.mounted) {
  //     if (data['type'] == 'announcement' ||
  //         (data['host'] == 'app' && data['path'] == '/announcements')) {
  //       AnnouncementModal.show(context, initialItems: []);
  //     }
  //   }
  // }

  static Future<void> init() async {
    // request permissions (crucial for android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('user declined push perms');
      return;
    }

    // Register token on start (handles cold start)
    await registerTokenWithBackend();

    // Subscribe to department topic
    await subscribeToDepartmentTopic();

    // listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await ApiService.registerFcmToken(newToken);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initial message on cold start
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // _handlePayload(initialMessage.data);
    }

    // foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('fg message rx: ${message.notification?.title}');
      // optionally show a custom in-app banner here since OS won't show system tray notif in fg
    });

    // app opened from system tray
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('app opened via tap, routing to payload: ${message.data}');
      // _handlePayload(message.data);
    });
  }

  /// Fetches the current FCM token and registers it with the backend if the user is logged in.
  static Future<void> registerTokenWithBackend() async {
    try {
      final isLoggedIn = await AuthManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('Skipping FCM registration: user not logged in');
        return;
      }

      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Registering current FCM token: $token');
        await ApiService.registerFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error during registerTokenWithBackend: $e');
    }
  }

  /// Subscribes the user to a topic based on their department name.
  static Future<void> subscribeToDepartmentTopic() async {
    try {
      final isLoggedIn = await AuthManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('Skipping department topic subscription: user not logged in');
        return;
      }

      final dept = AuthManager.department;
      if (dept != null && dept.isNotEmpty) {
        // Sanitize: lowercase and replace spaces/special characters with underscores
        // FCM topic regex: [a-zA-Z0-9-_.~%]{1,900}
        final sanitizedTopic = dept
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_'); // Collapse multiple underscores

        debugPrint('Subscribing to department topic: $sanitizedTopic');
        await _messaging.subscribeToTopic(sanitizedTopic);
      } else {
        debugPrint('No department found for user, skipping topic subscription');
      }
    } catch (e) {
      debugPrint('Error subscribing to department topic: $e');
    }
  }

  // pass a list of topics, e.g. ['all_users', 'delhi_branch', 'admins']
  static Future<void> syncTopics(
    List<String> topicsToSub,
    List<String> topicsToUnsub,
  ) async {
    for (String topic in topicsToSub) {
      await _messaging.subscribeToTopic(topic);
    }
    for (String topic in topicsToUnsub) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
