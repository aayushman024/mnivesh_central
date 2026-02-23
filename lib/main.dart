import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import this

import 'Managers/AuthManager.dart';
import 'Themes/AppTheme.dart';
import 'Services/download_service.dart';
import 'Providers/app_provider.dart'; // 2. Import the file where sharedPreferencesProvider is located

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Await the SharedPreferences instance
  final sharedPreferences = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  }

  DownloadService.init();

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

class MNiveshCentralApp extends ConsumerWidget {
  const MNiveshCentralApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'mNivesh Central',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}