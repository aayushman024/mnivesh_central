import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// needs to be top-level, isolate spins up without UI context
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("bg message rx: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

    // get the raw token if you need to map it to a user in your backend
    String? token = await _messaging.getToken();
    debugPrint('fcm token: $token');

    // listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      // push new token to backend here
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('fg message rx: ${message.notification?.title}');
      // optionally show a custom in-app banner here since OS won't show system tray notif in fg
    });

    // app opened from system tray
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('app opened via tap, routing to payload: ${message.data}');
      // handle deep linking / routing based on data payload
    });
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
