import 'package:flutter/foundation.dart';

import '../API/api_service.dart';
import '../Managers/AuthManager.dart';

class AppTokensService {
  static Future<void>? _syncFuture;

  static Future<void> syncInBackground({String trigger = 'manual'}) async {
    final existingSync = _syncFuture;
    if (existingSync != null) {
      return existingSync;
    }

    final syncFuture = _performSync(trigger: trigger);
    _syncFuture = syncFuture;

    try {
      await syncFuture;
    } finally {
      if (identical(_syncFuture, syncFuture)) {
        _syncFuture = null;
      }
    }
  }

  static Future<void> _performSync({required String trigger}) async {
    try {
      final isLoggedIn = await AuthManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint(
          '[AppTokens][$trigger] Skipping sync because user is not logged in.',
        );
        return;
      }

      final fetchedTokens = await ApiService.getMobileAppTokens();
      debugPrint('[AppTokens][$trigger] Received app tokens: $fetchedTokens');

      final storedTokens = await AuthManager.getStoredAppBackendTokens();
      if (_mapsEqual(storedTokens, fetchedTokens)) {
        debugPrint(
          '[AppTokens][$trigger] Stored app tokens are already up to date.',
        );
        return;
      }

      await AuthManager.saveAppBackendTokens(fetchedTokens);
      debugPrint('[AppTokens][$trigger] Stored app tokens updated.');
    } catch (error, stackTrace) {
      debugPrint('[AppTokens][$trigger] Failed to sync app tokens: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
