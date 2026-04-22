import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Views/Screens/AnnouncementModalScreen.dart';
import 'snackBar_Service.dart';

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

    // get the raw token if you need to map it to a user in your backend
    //String? token = await _messaging.getToken();

    // listen for token refreshes
    // _messaging.onTokenRefresh.listen((newToken) {
    //   // push new token to backend here
    // });

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
