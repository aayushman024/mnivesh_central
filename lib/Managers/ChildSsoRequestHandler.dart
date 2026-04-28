import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'AuthManager.dart';

class ChildSsoRequestHandler {
  static Future<bool> handle(Uri uri) async {
    if (uri.host != 'sso' || uri.path != '/request') {
      return false;
    }

    debugPrint("[SSO] Received SSO Request.");

    try {
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

      final prefs = await SharedPreferences.getInstance();
      final accessToken = AuthManager.accessToken;
      final refreshToken = AuthManager.refreshToken;
      final tokenType = AuthManager.tokenType;
      final kid = AuthManager.kid;

      late final Uri redirectUri;

      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint("[SSO] User is logged in. Gathering data...");

        final newParams = Map<String, String>.from(parsedCallback.queryParameters);
        newParams.addAll({
          'accessToken': accessToken,
          'refreshToken': refreshToken ?? '',
          'tokenType': tokenType ?? 'Bearer',
          'kid': kid ?? '',
          'name': prefs.getString('UserName') ?? '',
          'email': prefs.getString('UserEmail') ?? '',
          'departmentName': prefs.getString('user_department') ?? '',
          'associatedNumber': prefs.getString('workPhone') ?? '',
        });

        redirectUri = parsedCallback.replace(queryParameters: newParams);
      } else {
        debugPrint("[SSO] User NOT logged in. Returning error.");

        final newParams = Map<String, String>.from(parsedCallback.queryParameters);
        newParams['error'] = 'not_logged_in';
        redirectUri = parsedCallback.replace(queryParameters: newParams);
      }

      debugPrint("[SSO] Redirecting to: $redirectUri");
      await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("[SSO] Critical Error handling SSO request: $e");
    }

    return true;
  }
}
