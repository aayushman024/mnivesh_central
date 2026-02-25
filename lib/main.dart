import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import this

import 'Managers/AuthManager.dart';
import 'Themes/AppTheme.dart';
import 'Services/download_service.dart';
import 'Providers/app_provider.dart';
import 'Utils/Dimensions.dart'; // 2. Import the file where sharedPreferencesProvider is located
import 'Services/sync_service.dart'; // import sync service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Await the SharedPreferences instance
  final sharedPreferences = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  }

  if(Platform.isAndroid) {
    DownloadService.init();
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

class _MNiveshCentralAppState extends ConsumerState<MNiveshCentralApp> with WidgetsBindingObserver {

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
    return MaterialApp(
      title: 'mNivesh Central',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
    );
  }
}