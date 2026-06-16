import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import '../Managers/AuthManager.dart';
import 'analytics_service.dart';
import 'app_tokens_service.dart';
import 'connectivity_service.dart';
import 'download_service.dart';
import 'fcm_service.dart';
import 'sync_service.dart';
import 'updater_service.dart';

/// Centralised boot sequence.
///
/// ## Cold-start / resume flow (two-phase)
///
/// **Phase 1 — local storage read (fast, ~50-100 ms)**
/// [runCritical] calls [AuthManager.hydrate], which loads tokens from
/// secure-storage/shared-prefs into the in-memory cache.  The [ready]
/// gate is completed *immediately* after this — so every `await
/// BootstrapService.ready` call in the API layer unblocks as soon as
/// the locally-cached (still-valid) tokens are available, without
/// waiting for any network round-trip.
///
/// **Phase 2 — background network sync (fire-and-forget)**
/// After [ready] is signalled, a background task refreshes
/// app-backend tokens from the server.  [AuthManager]'s write-through
/// cache means every future [AuthManager.getAppToken] call will
/// automatically see the latest tokens once the sync completes —
/// without gating any API call on that network round-trip.
///
/// [runDeferred] is fire-and-forget — it warms up services that are
/// NOT required for the first meaningful frame.
class BootstrapService {
  const BootstrapService._();

  static Completer<void> _readyCompleter = Completer<void>();

  /// Resolves as soon as auth tokens are loaded from local storage.
  /// This is instant relative to any network call.  Subsequent API
  /// calls use the in-memory cache populated by [AuthManager.hydrate].
  static Future<void> get ready => _readyCompleter.future;

  // ── Critical path ───────────────────────────────────────────────
  static Future<void> runCritical() async {
    // Reset the gate on each cold-start cycle.
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }

    // ── Phase 1: fast storage read ──────────────────────────────
    // Reads tokens from secure-storage / shared-prefs into memory.
    // This is the ONLY thing API callers need to unblock.
    await AuthManager.hydrate();

    // Open the gate immediately — hydrated tokens are valid right now.
    // No API caller needs to wait for Phase 2.
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }

    // ── Phase 2: background network refresh (non-blocking) ──────
    // Fetches fresh app-backend tokens from the server and updates
    // the in-memory cache via AuthManager's write-through on completion.
    // API calls that arrive after the sync finishes will automatically
    // use the refreshed tokens.
    unawaited(_backgroundTokenSync('cold_start'));
  }

  // ── Resume helper ────────────────────────────────────────────────
  // Call this from AppLifecycleState.resumed instead of runCritical.
  //
  // Re-hydrates auth tokens from storage (in case they were refreshed
  // by an SSO/background process while the app was backgrounded), then
  // fires a background network sync — without stalling the UI or
  // blocking any in-flight API call.
  //
  // The [ready] gate is intentionally NOT reset here: it was already
  // completed on cold-start and the hydrated cache is still valid.
  static DateTime? _lastResumeSync;

  static Future<void> onResume() async {
    // Debounce: skip if a resume sync ran within the last 30 seconds.
    // This handles rapid background/foreground cycles (e.g. biometric
    // prompt, notification shade) without redundant network hits.
    final now = DateTime.now();
    if (_lastResumeSync != null &&
        now.difference(_lastResumeSync!) < const Duration(seconds: 30)) {
      debugPrint('[BootstrapService] Skipping resume sync — too soon.');
      return;
    }
    _lastResumeSync = now;

    // Re-hydrate in case the auth token was refreshed while backgrounded.
    await AuthManager.hydrate();

    // Background token refresh — does NOT block the caller.
    unawaited(_backgroundTokenSync('resume'));
  }

  static Future<void> _backgroundTokenSync(String trigger) async {
    try {
      await AppTokensService.syncInBackground(trigger: trigger);
    } catch (e) {
      debugPrint('[BootstrapService] App token sync failed ($trigger): $e');
    }
  }

  // ── Deferred path ──────────────────────────────────────────────
  // Everything here runs AFTER the first Flutter frame is drawn.
  // One-time platform inits (FlutterDownloader, Firebase, FCM) are
  // guarded so they only execute on the first cold start.
  static bool _platformInitDone = false;

  static Future<void> runDeferred() async {
    if (!_platformInitDone) {
      _platformInitDone = true;
      ConnectivityService.init();

      if (Platform.isAndroid) {
        await Future.wait([
          FlutterDownloader.initialize(
            debug: kDebugMode,
            ignoreSsl: kDebugMode,
          ),
          Firebase.initializeApp(),
        ]);

        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        DownloadService.init();

        // FCM needs Firebase, so it runs after the Future.wait above
        unawaited(
          FCMService.init()
              .then((_) => FCMService.syncTopics(['all_users'], [])),
        );
      }
    }

    unawaited(
      AnalyticsService.initialize()
          .then((_) => AnalyticsService.syncUserContext()),
    );
    unawaited(SyncService.syncNow());
    unawaited(UpdaterService.checkForUpdates());
  }
}
