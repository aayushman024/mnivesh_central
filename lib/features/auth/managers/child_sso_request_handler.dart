import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:mnivesh_central/features/auth/widgets/sso_authorization_bottom_sheet.dart';

import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';

class ChildSsoRequestHandler {
  static Future<bool> handle(Uri uri, BuildContext context) async {
    if (uri.host != 'sso' || uri.path != '/request') {
      return false;
    }

    debugPrint("[SSO] Received SSO Request.");

    try {
      // Validate timestamp (60 seconds threshold for drift)
      final timestampStr = uri.queryParameters['t'] ?? uri.queryParameters['timestamp'];
      if (timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final ms = timestampStr.length <= 10 ? timestamp * 1000 : timestamp;
          final diff = (now - ms).abs();
          if (diff > 60000) {
            debugPrint("[SSO] Stale SSO request blocked (diff: ${diff}ms, url t: $ms, now: $now)");
            return true; // Consume the intent and block stale execution
          }
        }
      }

      final callbackUrlString = uri.queryParameters['callback'];
      if (callbackUrlString == null || callbackUrlString.isEmpty) {
        debugPrint("[SSO] Error: 'callback' parameter is missing.");
        return true;
      }

      final parsedCallback = Uri.tryParse(callbackUrlString);
      if (parsedCallback == null) {
        debugPrint("[SSO] Error: Invalid callback URI format: $callbackUrlString");
        return true;
      }

      // Check if user is logged in
      final accessToken = AuthManager.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint("[SSO] User NOT logged in. Returning error immediately.");
        final newParams = Map<String, String>.from(parsedCallback.queryParameters);
        newParams['error'] = 'not_logged_in';
        final redirectUri = parsedCallback.replace(queryParameters: newParams);
        debugPrint("[SSO] Redirecting to: $redirectUri");
        await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Extract app name
      String appName = parsedCallback.scheme.toUpperCase();
      if (parsedCallback.scheme == 'http' || parsedCallback.scheme == 'https') {
        final host = parsedCallback.host;
        if (host.isNotEmpty) {
          final parts = host.split('.');
          if (parts.length > 1) {
            appName = parts[parts.length - 2].toUpperCase();
          } else {
            appName = host.toUpperCase();
          }
        }
      }

      // Show bottom sheet
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => SsoAuthorizationBottomSheet(
            appName: appName,
            onCancel: () {
              Navigator.pop(sheetContext);
              debugPrint("[SSO] User cancelled login request.");
            },
            onConfirm: (data) async {
              Navigator.pop(sheetContext);
              debugPrint("[SSO] User approved login request. Fetching tokens...");
              
              // Hydrate latest data before redirecting to avoid stale tokens
              await AuthManager.hydrate();
              final latestAccessToken = AuthManager.accessToken;
              final latestRefreshToken = AuthManager.refreshToken;
              final latestTokenType = AuthManager.tokenType;
              final latestKid = AuthManager.kid;

              if (latestAccessToken == null || latestAccessToken.isEmpty) {
                debugPrint("[SSO] Error: Latest tokens are missing after confirmation.");
                return;
              }

              final newParams = Map<String, String>.from(parsedCallback.queryParameters);
              newParams.addAll({
                'accessToken': latestAccessToken,
                'tokenType': latestTokenType ?? 'Bearer',
              });

              if (latestRefreshToken != null && latestRefreshToken.isNotEmpty) {
                newParams['refreshToken'] = latestRefreshToken;
              }
              if (latestKid != null && latestKid.isNotEmpty) {
                newParams['kid'] = latestKid;
              }

              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '';
              final dept = data['dept'] ?? '';

              if (name.trim().isNotEmpty) {
                newParams['name'] = name.trim();
              }
              if (email.trim().isNotEmpty) {
                newParams['email'] = email.trim();
              }
              if (dept.trim().isNotEmpty) {
                newParams['departmentName'] = dept.trim();
              }
              if (phone.trim().isNotEmpty) {
                newParams['associatedNumber'] = phone.trim();
              }

              final redirectUri = parsedCallback.replace(queryParameters: newParams);
              debugPrint("[SSO] Redirecting to child app: $redirectUri");
              await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
            },
          ),
        );
      }

    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'SSO request handler failed');
      debugPrint("[SSO] Critical Error handling SSO request: $e");
    }

    return true;
  }
}
