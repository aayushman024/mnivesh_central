import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import this

import 'Managers/AuthManager.dart';
import 'Providers/app_provider.dart';
import 'Services/download_service.dart';
import 'Services/fcm_service.dart';
import 'Services/snackBar_Service.dart';
import 'Services/sync_service.dart'; // import sync service
import 'Themes/AppTheme.dart';
import 'Utils/Dimensions.dart';
import 'Utils/DismissKeyboard.dart'; // 2. Import the file where sharedPreferencesProvider is located

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Await the SharedPreferences instance
  final sharedPreferences = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    DownloadService.init();
  }

  //fcm init
  if (Platform.isAndroid) {
    await Firebase.initializeApp();
    await FCMService.init();
    await FCMService.syncTopics(['all_users'], []);
  }
  runApp(
    ProviderScope(
      // 4. Override the unimplemented provider with the real instance
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MNiveshCentralApp(),
    ),
  );
}

// changed to ConsumerStatefulWidget to hook into lifecycle states
class MNiveshCentralApp extends ConsumerStatefulWidget {
  const MNiveshCentralApp({super.key});

  @override
  ConsumerState<MNiveshCentralApp> createState() => _MNiveshCentralAppState();
}

class _MNiveshCentralAppState extends ConsumerState<MNiveshCentralApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // start observing lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    SyncService.syncNow();
  }

  @override
  void dispose() {
    // cleanup observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SyncService.syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return DismissKeyboard(
      child: MaterialApp(
        title: 'mNivesh Central',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        scaffoldMessengerKey: SnackbarService.messengerKey,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // wrap with OrientationBuilder so SizeUtil catches rotation changes dynamically
          return OrientationBuilder(
            builder: (context, orientation) {
              SizeUtil.init(context);
              return child!;
            },
          );
        },
        home: const AuthWrapper(),
      ),
    );
  }
}
