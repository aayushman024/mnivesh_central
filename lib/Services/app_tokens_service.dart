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
        debugPrint('[AppTokens][$trigger] Skipping sync — user not logged in.');
        return;
      }

      final fetchedTokens = await ApiService.getMobileAppTokens();
      debugPrint('[AppTokens][$trigger] Fetched ${fetchedTokens.length} app token(s) from server.');

      final normalizedFetched = {
        for (final e in fetchedTokens.entries)
          e.key.trim().toUpperCase(): e.value.trim(),
      };

      final storedTokens = await AuthManager.getStoredAppBackendTokens();
      if (_mapsEqual(storedTokens, normalizedFetched)) {
        debugPrint('[AppTokens][$trigger] Stored tokens are already up to date. No changes made.');
        return;
      }

      await AuthManager.saveAppBackendTokens(fetchedTokens);
      debugPrint('[AppTokens][$trigger] Tokens updated. Stored ${fetchedTokens.length} app token(s).');
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