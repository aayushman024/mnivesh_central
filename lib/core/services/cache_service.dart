import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:path_provider/path_provider.dart';

/// A service to manage application cache (Temporary Directory) on Android and iOS.
/// This service provides utilities to calculate cache size and clear it safely.
class CacheService {
  /// Returns the total size of the app's temporary (cache) directory in bytes.
  /// 
  /// Uses [compute] to perform the recursive directory traversal in a background isolate,
  /// preventing UI jank when dealing with large numbers of files.
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return 0;

      // Use compute to move the I/O intensive walking to another isolate
      return await compute(_calculateSize, tempDir.path);
    } catch (e) {
      debugPrint("CacheService: Error getting cache size: $e");
      return 0;
    }
  }

  /// Static helper for [compute] to calculate directory size recursively.
  /// 
  /// [path] The absolute path to the directory to calculate.
  static int _calculateSize(String path) {
    int totalSize = 0;
    try {
      final dir = Directory(path);
      if (dir.existsSync()) {
        // We use listSync here because we are already in a background isolate
        final files = dir.listSync(recursive: true, followLinks: false);
        for (var file in files) {
          if (file is File) {
            try {
              totalSize += file.lengthSync();
            } catch (e) {
              // Skip files that are inaccessible or deleted during calculation
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("CacheService: Error walking directory $path: $e");
    }
    return totalSize;
  }

  /// Clears the application cache and Flutter internal image cache.
  /// 
  /// This targets:
  /// 1. The 'Temporary' directory (Caches on iOS, cache on Android).
  /// 2. Flutter's [ImageCache] in memory.
  /// 
  /// It does NOT touch:
  /// - Shared Preferences / Secure Storage
  /// Application Documents
  static Future<void> clearCache() async {
    try {
      // 1. Clear physical files in the temporary directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final children = tempDir.listSync();
        for (final child in children) {
          try {
            // Delete recursively to handle sub-folders within cache
            child.deleteSync(recursive: true);
          } catch (e) {
            // Silently fail for individual files that might be locked by the OS or app
            debugPrint("CacheService: Could not delete ${child.path}: $e");
          }
        }
      }

      // 2. Clear Flutter's memory image cache
      // This is crucial for freeing up GPU/System RAM immediately
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      SnackbarService.showSuccess("Cache cleared successfully");
      debugPrint("CacheService: Cache cleared successfully.");
    } catch (e) {
      debugPrint("CacheService: Error during cache clearing: $e");
    }
  }

  /// Formats a byte count into a human-readable string (e.g., "1.45 MB").
  /// 
  /// [bytes] The number of bytes.
  /// [decimals] How many decimal places to show (default: 2).
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();

    // Clamp index to available suffixes
    i = i.clamp(0, suffixes.length - 1);
    
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
