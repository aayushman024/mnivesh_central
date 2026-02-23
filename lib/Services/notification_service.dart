// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart'; // Required for SnackBar and Colors
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   if (kDebugMode) print("Handling a background message: ${message.messageId}");
// }
//
// class NotificationService {
//   // 1. Define the GlobalKey here
//   static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
//
//   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//   static Future<void> init() async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true, badge: true, sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       await _firebaseMessaging.subscribeToTopic('app_updates');
//     }
//
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//     // 4. Handle Foreground Messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.notification != null) {
//         // Use the messengerKey to show the SnackBar
//         messengerKey.currentState?.showSnackBar(
//           SnackBar(
//             content: Text(
//               message.notification!.title ?? 'New Update Available',
//               style: const TextStyle(color: Colors.white),
//             ),
//             backgroundColor: const Color(0xFF7C4DFF), // Matches your AppTheme primary color
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sdp)),
//             margin: const EdgeInsets.all(10.sdp),
//             duration: const Duration(seconds: 4),
//           ),
//         );
//       }
//     });
//   }
// }

import 'package:flutter/material.dart';

class NotificationService {
  // Keeping the GlobalKey so main.dart doesn't break
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static Future<void> init() async {
    // FCM completely skipped for now
    // We can re-implement Firebase Messaging later when requested
  }
}