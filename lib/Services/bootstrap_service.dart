import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
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
/// [runCritical] must finish before the auth-gated UI is shown.
/// It also syncs app-backend tokens so that API services gated on
/// [ready] can build authenticated headers immediately.
///
/// [runDeferred] is fire-and-forget — it warms up services that are
/// NOT required for the first meaningful frame.
class BootstrapService {
  const BootstrapService._();

  static Completer<void> _readyCompleter = Completer<void>();

  /// Resolves once auth tokens AND app-backend tokens are loaded.
  /// Instant after the first cold-start resolution.
  static Future<void> get ready => _readyCompleter.future;

  // ── Critical path ───────────────────────────────────────────────
  // 1. Hydrates cached tokens into memory (auth + app-backend).
  // 2. Syncs app-backend tokens from the server.
  // 3. Signals [ready] so gated API calls can proceed.
  static Future<void> runCritical() async {
    // Reset the gate on each cold-start / resume cycle
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }

    await AuthManager.hydrate();

    // Sync app-backend tokens, then open the gate.
    // Even if sync fails, we still complete — hydrated cache
    // may still hold valid tokens from a previous session.
    try {
      await AppTokensService.syncInBackground(trigger: 'cold_start');
    } catch (e) {
      debugPrint('[BootstrapService] App token sync failed: $e');
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
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
