import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // added for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Managers/AuthWrapper.dart';
import 'Providers/app_provider.dart';
import 'Services/connectivity_service.dart';
import 'Services/download_service.dart';
import 'Services/app_tokens_service.dart';
import 'Services/fcm_service.dart';
import 'Services/snackBar_Service.dart';
import 'Services/sync_service.dart';
import 'Themes/AppTheme.dart';
import 'Utils/Dimensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    await _initAndroidServices();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MNiveshCentralApp(),
    ),
  );
}

// consolidated android setups running concurrently where possible
Future<void> _initAndroidServices() async {
  await Future.wait([
    FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: kDebugMode),
    Firebase.initializeApp(),
  ]);

  DownloadService.init();

  // FCM needs Firebase to finish first
  await FCMService.init();
  await FCMService.syncTopics(['all_users'], []);
}

class MNiveshCentralApp extends ConsumerStatefulWidget {
  const MNiveshCentralApp({super.key});

  @override
  ConsumerState<MNiveshCentralApp> createState() => _MNiveshCentralAppState();
}

class _MNiveshCentralAppState extends ConsumerState<MNiveshCentralApp>
    with WidgetsBindingObserver {
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ConnectivityService.init();

    // push sync to next frame so we don't delay initial paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(SyncService.syncNow());
      unawaited(AppTokensService.syncInBackground(trigger: 'cold_start'));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SyncService.syncNow();
      unawaited(AppTokensService.syncInBackground(trigger: 'app_resumed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'mNivesh Central',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: SnackbarService.navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OrientationBuilder(
          builder: (context, orientation) {
            // only init SizeUtil if orientation actually changes to save cpu cycles
            if (_lastOrientation != orientation) {
              _lastOrientation = orientation;
              SizeUtil.init(context);
            }
            return child!;
          },
        );
      },
      home: const AuthWrapper(),
    );
  }
}
