import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageNotifier extends StateNotifier<String?> {
  ProfileImageNotifier() : super(null);

  Future<void> init(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) {
      state = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_profile_image_path');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedPath = prefs.getString('local_profile_image_path');

    if (cachedPath != null && File(cachedPath).existsSync()) {
      state = cachedPath;
    }

    // Download/refresh the image asynchronously on cold start (only once per app launch session)
    _downloadImage(photoUrl);
  }

  Future<void> _downloadImage(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile_picture.png';

      final dio = Dio();
      await dio.download(url, filePath);

      final file = File(filePath);
      if (await file.exists()) {
        state = filePath;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_profile_image_path', filePath);
        debugPrint('[ProfileImageNotifier] Successfully cached profile image locally: $filePath');
      }
    } catch (e) {
      debugPrint('[ProfileImageNotifier] Error downloading profile image: $e');
    }
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_profile_image_path');
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_picture.png');
      if (file.existsSync()) {
        await file.delete();
      }
      debugPrint('[ProfileImageNotifier] Successfully cleared profile image cache.');
    } catch (e) {
      debugPrint('[ProfileImageNotifier] Error clearing profile image file: $e');
    }
  }
}

final profileImageProvider = StateNotifierProvider<ProfileImageNotifier, String?>((ref) {
  return ProfileImageNotifier();
});
