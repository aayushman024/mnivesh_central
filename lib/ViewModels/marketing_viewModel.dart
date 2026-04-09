import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mnivesh_central/API/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../API/api_client.dart';
import '../API/api_service.dart';
import '../Models/marketing_model.dart';

class MarketingViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<MarketingSectionData> sections = [];

  Dio get _dio => ApiClient.getDio(ApiConfig.defaultBaseUrl);

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    // fake network delay
    // TODO: wire this up to the actual marketing endpoint later

    // swapped placeholder.com for picsum seeds to test actual image rendering/caching
    sections = [
      MarketingSectionData(
        title: 'Marketing Collateral',
        imageUrls: [
          'https://picsum.photos/seed/koti/400/500',
          'https://picsum.photos/seed/star/400/500',
          'https://picsum.photos/seed/hdfc/400/500',
        ],
      ),
      MarketingSectionData(
        title: 'Marketing',
        imageUrls: [
          'https://picsum.photos/seed/koti2/400/500',
          'https://picsum.photos/seed/star2/400/500',
        ],
      ),
      MarketingSectionData(
        title: 'Festivals',
        imageUrls: [
          'https://picsum.photos/seed/koti5/400/500',
          'https://picsum.photos/seed/star6/400/500',
        ],
      ),
    ];

    isLoading = false;
    notifyListeners();
  }

  Future<bool> shareImage(String imageUrl, {String? shareText}) async {
    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          // fail fast on network hangs rather than locking the user out
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('Share failed: Invalid HTTP status ${response.statusCode}');
        return false;
      }

      // group shared files in a dedicated folder so they don't clutter the temp dir root
      final tempDir = await getTemporaryDirectory();
      final shareCacheDir = Directory('${tempDir.path}/share_cache');
      if (!await shareCacheDir.exists()) {
        await shareCacheDir.create(recursive: true);
      }

      final fileName = 'marketing_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${shareCacheDir.path}/$fileName');

      await file.writeAsBytes(response.data!);

      final result = await Share.shareXFiles([
        XFile(file.path),
      ], text: shareText ?? 'Check out this marketing material!');

      // clean up the file immediately after the share sheet closes so we don't leak storage
      if (await file.exists()) {
        await file.delete();
      }

      return result.status == ShareResultStatus.success;
    } on DioException catch (e) {
      // TODO: push this to crashlytics/sentry
      debugPrint('Network error during share: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during share: $e');
      return false;
    }
  }

  Future<void> downloadImage(String imageUrl) async {
    // TODO: implement image_gallery_saver logic
    debugPrint('Downloading: $imageUrl');
  }
}
