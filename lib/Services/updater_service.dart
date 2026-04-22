import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter/foundation.dart';
import 'snackBar_Service.dart';

class UpdaterService {
  static final ShorebirdUpdater _updater = ShorebirdUpdater();
  static bool _isChecking = false;

  /// Checks for available patches via Shorebird and applies them.
  /// If a patch is successfully downloaded and staged, it displays a sticky snackbar.
  static Future<void> checkForUpdates() async {
    // Only check if we are not already checking
    if (_isChecking) return;

    try {
      _isChecking = true;

      // Check if a patch is available
      final updateStatus = await _updater.checkForUpdate();

      if (updateStatus == UpdateStatus.outdated) {
        debugPrint('Shorebird update available, downloading...');
        // Download and stage the update for next cold start
        await _updater.update();
        debugPrint('Shorebird update successfully downloaded and staged.');

        // Notify the user with a sticky snackbar
        SnackbarService.showUpdateReady();
      } else {
        debugPrint('Shorebird status: $updateStatus. No update needed.');
      }
    } on UpdateException catch (e) {
      debugPrint('Shorebird UpdateException: ${e.message}');
    } catch (e) {
      debugPrint('Shorebird update error: $e');
    } finally {
      _isChecking = false;
    }
  }
}
