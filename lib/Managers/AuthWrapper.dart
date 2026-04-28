import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';

import '../Services/app_tokens_service.dart';
import '../Services/analytics_service.dart';
import '../Views/Screens/LoginScreen.dart';
import '../Views/Screens/MainScreen.dart';
import 'AuthManager.dart';
import 'ChildSsoRequestHandler.dart';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLoginState();
    }
  }

  Future<void> _checkLoginState() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final isLoggedIn = await AuthManager.isLoggedIn();

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint("--- [DeepLink] Received URI: $uri ---");

    if (AuthManager.isLogoutInProgress) {
      debugPrint('[Auth] Ignoring deep link while logout is in progress.');
      return;
    }

    if (await ChildSsoRequestHandler.handle(uri)) {
      return;
    }

    if (uri.host != 'auth' || uri.path != '/callback') {
      return;
    }

    final canHandleCallback = await AuthManager.consumePendingLoginFlow();
    if (!canHandleCallback) {
      debugPrint('[Auth] Ignoring stale or duplicate login callback.');
      return;
    }

    debugPrint("[Auth] Handling login callback...");

    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      await AnalyticsService.logLoginFailed(error);
      SnackbarService.showError(error);
      debugPrint("[Auth] Login failed: $error");
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];
    final tokenType = uri.queryParameters['tokenType'];
    final kid = uri.queryParameters['kid'];

    if (accessToken == null || accessToken.isEmpty) {
      await AnalyticsService.logLoginFailed('missing_access_token');
      debugPrint("[Auth] Error: Access token missing in callback.");
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      await AuthManager.saveAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        kid: kid,
        name: uri.queryParameters['name'],
        email: uri.queryParameters['email'],
        associatedNumber: uri.queryParameters['associatedNumber'],
        departmentName: uri.queryParameters['departmentName'],
      );

      unawaited(AppTokensService.syncInBackground(trigger: 'post_login'));
      unawaited(AnalyticsService.logLoginSuccess());

      debugPrint("[Auth] Login successful. Reloading state.");
      await _checkLoginState();
    } catch (e) {
      await AnalyticsService.logLoginFailed('session_persist_failed');
      debugPrint("[Auth] Failed to persist auth session: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return _isLoggedIn ? const MainScreen() : const ZohoLoginScreen();
  }
}
