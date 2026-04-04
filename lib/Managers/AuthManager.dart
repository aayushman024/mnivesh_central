import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Views/Screens/MainScreen.dart';
import '../Views/Screens/LoginScreen.dart';

class AuthManager {
  static const String _authToken = "AuthToken";
  static const String _userName = "UserName";
  static const String _userEmail = "UserEmail";
  static const String _userDepartment = "user_department";
  static const String _workPhone = "workPhone";

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_authToken);
  }

  static Future<void> saveDetails({
    required String token,
    String? department,
    String? email,
    String? workPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authToken, token);
    if (department != null) await prefs.setString(_userDepartment, department);
    if (email != null) await prefs.setString(_userEmail, email);
    if (workPhone != null) await prefs.setString(_workPhone, workPhone);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authToken);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userName, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userName);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

// --- Auth Wrapper to handle Deep Links, SharedPreferences, and Lifecycle ---

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    _checkLoginState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Handle app resumes to re-check login state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLoginState();
    }
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the consistent key "AuthToken"
    final token = prefs.getString("AuthToken");

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint("--- [DeepLink] Received URI: $uri ---");

    // 1. ZOHO LOGIN CALLBACK (Store App Login)
    if (uri.host == 'auth' && uri.path == '/callback') {
      debugPrint("[Auth] Handling Zoho Callback...");

      final token = uri.queryParameters['token'];
      final department = uri.queryParameters['department'];
      final email = uri.queryParameters['email'];
      final name = uri.queryParameters['name'];
      final workPhone = uri.queryParameters['work_phone'];

      if (token != null && token.isNotEmpty) {
        setState(() => _isLoading = true);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("AuthToken", token);
        if (department != null) await prefs.setString("user_department", department);
        if (email != null) await prefs.setString("UserEmail", email);
        if (name != null) await prefs.setString("UserName", name);
        if (workPhone != null) await prefs.setString("workPhone", workPhone);

        debugPrint("[Auth] Login Successful. Reloading state.");
        _checkLoginState();
      } else {
        debugPrint("[Auth] Error: Token missing in callback.");
      }
    }

    // 2. SSO REQUEST FROM CHILD APPS
    if (uri.host == 'sso' && uri.path == '/request') {
      debugPrint("[SSO] Received SSO Request.");

      try {
        // The child app tells us where to send the data back
        final callbackUrlString = uri.queryParameters['callback'];

        if (callbackUrlString == null || callbackUrlString.isEmpty) {
          debugPrint("[SSO] Error: 'callback' parameter is missing.");
          return;
        }

        final Uri? parsedCallback = Uri.tryParse(callbackUrlString);
        if (parsedCallback == null) {
          debugPrint("[SSO] Error: Invalid callback URI format: $callbackUrlString");
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("AuthToken");

        Uri redirectUri;

        if (token != null && token.isNotEmpty) {
          debugPrint("[SSO] User is logged in. Gathering data...");

          final name = prefs.getString("UserName") ?? '';
          final email = prefs.getString("UserEmail") ?? '';
          final dept = prefs.getString("user_department") ?? '';
          final workPhone = prefs.getString("workPhone") ?? '';

          // MERGE existing query params with new SSO data
          // This ensures we don't wipe out params the child app might have sent (e.g. session_id)
          final Map<String, String> newParams = Map.from(parsedCallback.queryParameters);
          newParams.addAll({
            'token': token,
            'name': name,
            'email': email,
            'department': dept,
            'work_phone': workPhone,
          });

          redirectUri = parsedCallback.replace(queryParameters: newParams);

        } else {
          debugPrint("[SSO] User NOT logged in. Returning error.");

          // Merge error param
          final Map<String, String> newParams = Map.from(parsedCallback.queryParameters);
          newParams['error'] = 'not_logged_in';

          redirectUri = parsedCallback.replace(queryParameters: newParams);
        }

        // Blast the data back to the child app
        debugPrint("[SSO] Redirecting to: $redirectUri");
        await launchUrl(redirectUri, mode: LaunchMode.externalApplication);

      } catch (e) {
        debugPrint("[SSO] Critical Error handling SSO request: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121218),
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return _isLoggedIn ? const MainScreen() : const ZohoLoginScreen();
  }
}