import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../API/api_config.dart';
import '../Managers/AuthManager.dart';

class AnalyticsService {
  const AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static bool get isReady => _analytics != null;

  static Future<void> initialize() async {
    await _ensureReady();
  }

  static Future<void> syncUserContext() async {
    await _ensureReady();
    if (_analytics == null) {
      return;
    }

    await Future.wait([
      _analytics!.setUserProperty(
        name: 'platform',
        value: Platform.isAndroid ? 'android' : Platform.operatingSystem,
      ),
      _analytics!.setUserProperty(
        name: 'app_version',
        value: ApiConfig.appVersion,
      ),
      _analytics!.setUserProperty(
        name: 'login_state',
        value: (await AuthManager.isLoggedIn()) ? 'logged_in' : 'logged_out',
      ),
      _analytics!.setUserProperty(
        name: 'department',
        value: _trimForProperty(AuthManager.department),
      ),
    ]);
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _runSafely(() async {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    });
  }

  static Future<void> logLoginStarted() async {
    await _logEvent('login_started', {'method': 'zoho'});
  }

  static Future<void> logLoginSuccess() async {
    await _logEvent('login_success', {'method': 'zoho'});
    await syncUserContext();
  }

  static Future<void> logLoginFailed(String reason) async {
    await _logEvent('login_failed', {
      'method': 'zoho',
      'reason': _trimForParam(reason),
    });
  }

  static Future<void> logStoreOpened({String source = 'navigation'}) async {
    await _logEvent('store_opened', {'source': _trimForParam(source)});
  }

  static Future<void> logAppInstallClicked({
    required String appName,
    required String packageName,
    required String version,
  }) async {
    await _logEvent('app_install_clicked', {
      'app_name': _trimForParam(appName),
      'package_name': _trimForParam(packageName),
      'target_version': _trimForParam(version),
    });
  }

  static Future<void> logAppUpdateClicked({
    required String appName,
    required String packageName,
    required String targetVersion,
    String? installedVersion,
  }) async {
    await _logEvent('app_update_clicked', {
      'app_name': _trimForParam(appName),
      'package_name': _trimForParam(packageName),
      'target_version': _trimForParam(targetVersion),
      'installed_version': _trimForParam(installedVersion),
    });
  }

  static Future<void> _logEvent(
    String name,
    Map<String, Object?> parameters,
  ) async {
    await _runSafely(() async {
      if (_analytics == null) {
        return;
      }

      final cleaned = <String, Object>{};
      for (final entry in parameters.entries) {
        final value = entry.value;
        if (value == null) continue;
        cleaned[entry.key] = value;
      }

      await _analytics!.logEvent(name: name, parameters: cleaned);
    });
  }

  static Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await _ensureReady();
      await action();
    } catch (error, stackTrace) {
      debugPrint('[AnalyticsService] $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _ensureReady() async {
    if (_analytics != null || Firebase.apps.isEmpty) {
      return;
    }

    _analytics = FirebaseAnalytics.instance;
    await _analytics!.setAnalyticsCollectionEnabled(true);
  }

  static String? _trimForParam(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
  }

  static String? _trimForProperty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.length <= 36 ? trimmed : trimmed.substring(0, 36);
  }
}
