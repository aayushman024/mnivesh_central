import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {

  static Future<void> requestAll() async {
    if (!Platform.isAndroid) return; // iOS bypass

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }
  }
}