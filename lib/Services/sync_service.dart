// lib/Services/sync_service.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SyncService {
  // 5-minute cooldown for quick open/close cycles
  static const Duration _syncCooldown = Duration(seconds: 30);

  static Future<void> syncNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Quick open/close check
      final lastSyncStr = prefs.getString('LastSyncTimestamp');
      if (lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        if (DateTime.now().difference(lastSync) < _syncCooldown) return;
      }

      final token = prefs.getString('AuthToken');
      if (token == null || token.isEmpty) return;

      // Device Metadata
      String deviceModel = "Unknown";
      String osVersion = "Unknown";
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
        osVersion = "Android ${androidInfo.version.release}";
      }

      // Format: appName(appVersionInstalled)
      final allStoreApps = await ApiService().fetchApps(token);
      List<String> installedAppsFormatted = [];

      for (var app in allStoreApps) {
        final isInstalled = await InstalledApps.isAppInstalled(app.packageName) ?? false;
        if (isInstalled) {
          final info = await InstalledApps.getAppInfo(app.packageName);
          final version = info?.versionName ?? "Unknown";
          installedAppsFormatted.add("${app.appName}($version)");
        }
      }

      final payload = {
        "username": prefs.getString('UserName') ?? 'User',
        "email": prefs.getString('UserEmail') ?? 'N/A',
        "department": prefs.getString('user_department') ?? 'N/A',
        "phoneDetails": {
          "deviceModel": deviceModel,
          "osVersion": osVersion
        },
        "appsInstalled": installedAppsFormatted,
        "lastSeen": DateTime.now().toUtc().toIso8601String()
      };

      await ApiService.postUserDetails(payload, token);
      await prefs.setString('LastSyncTimestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print("Sync error: $e");
    }
  }
}