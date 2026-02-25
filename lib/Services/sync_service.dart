// lib/Services/sync_service.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SyncService {
  // 5-minute cooldown to prevent server spamming on quick open/close
  static const Duration _syncCooldown = Duration(seconds: 30);

  static Future<void> syncNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastSyncStr = prefs.getString('LastSyncTimestamp');
      if (lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        if (DateTime.now().difference(lastSync) < _syncCooldown) return;
      }

      final token = prefs.getString('AuthToken');
      if (token == null || token.isEmpty) return;

      String deviceModel = "Unknown";
      String osVersion = "Unknown";
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
        osVersion = "Android ${androidInfo.version.release}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.modelName;
        osVersion = "iOS ${iosInfo.systemVersion}";
      }

      List<String> installedAppsFormatted = [];

      // skip installed apps check on iOS to avoid app store rejection
      if (Platform.isAndroid) {
        final allStoreApps = await ApiService().fetchApps(token);
        for (var app in allStoreApps) {
          final isInstalled = await InstalledApps.isAppInstalled(app.packageName) ?? false;
          if (isInstalled) {
            final info = await InstalledApps.getAppInfo(app.packageName);
            final version = info?.versionName ?? "Unknown";
            installedAppsFormatted.add("${app.appName}($version)");
          }
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

      print(payload);

      await ApiService.postUserDetails(payload, token);
      await prefs.setString('LastSyncTimestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print("Sync error: $e");
    }
  }
}