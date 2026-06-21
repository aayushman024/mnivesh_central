import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mnivesh_central/features/marketing/utils/marketing_image_util.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';

class RouteVisitImageUtil {
  static final Dio _dio = Dio();

  // Helper to download a URL to a temporary file
  static Future<File?> downloadUrlToTempFile(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      if (response.data == null) return null;

      final bytes = Uint8List.fromList(response.data!);
      final tempDir = await getTemporaryDirectory();
      
      // Sanitise filename
      final uri = Uri.parse(url);
      final rawFileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image';
      final cleanFileName = rawFileName.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
      
      final suffix = '${DateTime.now().millisecondsSinceEpoch}';
      final fileName = 'visit_${suffix}_$cleanFileName';
      
      // Ensure file name has extension
      final finalPath = fileName.contains('.') ? fileName : '$fileName.png';
      final file = File('${tempDir.path}/$finalPath');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error downloading URL to temp file: $e');
      return null;
    }
  }

  // Download a single URL to gallery
  static Future<void> downloadUrlToGallery(String url, String title) async {
    try {
      final file = await downloadUrlToTempFile(url);
      if (file == null) {
        throw Exception('Failed to download image from server.');
      }
      await MarketingImageUtil.saveToGallery(file, title);
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      SnackbarService.showError('Could not save image: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Share a single URL
  static Future<void> shareUrl(String url, {String? text}) async {
    try {
      final file = await downloadUrlToTempFile(url);
      if (file == null) {
        throw Exception('Failed to download image.');
      }
      await MarketingImageUtil.shareFile(file, text: text ?? 'Attached visit completion image');
    } catch (e) {
      debugPrint('Error sharing image: $e');
      SnackbarService.showError('Could not share image');
    }
  }

  // Download all URLs to gallery in parallel
  static Future<void> downloadAllToGallery(List<String> urls, String baseTitle) async {
    try {
      SnackbarService.showSuccess('Downloading ${urls.length} images to gallery...');
      
      // Download in parallel
      final downloadFutures = urls.map((url) => downloadUrlToTempFile(url)).toList();
      final files = await Future.wait(downloadFutures);

      final validFiles = files.whereType<File>().toList();
      if (validFiles.isEmpty) {
        throw Exception('Failed to download any images.');
      }

      int successCount = 0;
      for (int i = 0; i < validFiles.length; i++) {
        try {
          final file = validFiles[i];
          final title = '${baseTitle}_${i + 1}';
          await MarketingImageUtil.saveToGallery(file, title);
          successCount++;
        } catch (e) {
          debugPrint('Error saving bulk image $i: $e');
        }
      }

      if (successCount == validFiles.length) {
        SnackbarService.showSuccess('All $successCount images saved successfully!');
      } else {
        SnackbarService.showSuccess('Saved $successCount of ${urls.length} images.');
      }
    } catch (e) {
      debugPrint('Error during download all: $e');
      SnackbarService.showError('Download all failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Share all URLs in parallel
  static Future<void> shareAllUrls(List<String> urls, {String? text}) async {
    final List<File> tempFiles = [];
    try {
      SnackbarService.showSuccess('Preparing ${urls.length} images to share...');

      // Download in parallel
      final downloadFutures = urls.map((url) => downloadUrlToTempFile(url)).toList();
      final files = await Future.wait(downloadFutures);

      tempFiles.addAll(files.whereType<File>());
      if (tempFiles.isEmpty) {
        throw Exception('Failed to download any images to share.');
      }

      final xFiles = tempFiles.map((file) => XFile(file.path)).toList();
      await Share.shareXFiles(xFiles, text: text ?? 'Attached visit completion images');
    } catch (e) {
      debugPrint('Error during share all: $e');
      SnackbarService.showError('Share all failed');
    } finally {
      // Clean up files safely
      for (final file in tempFiles) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (cleanupErr) {
          debugPrint('Cleanup failed for ${file.path}: $cleanupErr');
        }
      }
    }
  }
}
