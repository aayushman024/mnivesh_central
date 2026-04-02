import 'package:connectivity_plus/connectivity_plus.dart';
import 'snackBar_Service.dart';

class ConnectivityService {
  // track last state so we don't trigger redundant snackbars
  static bool _wasOffline = false;

  static void init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // check if we have any active network interface
      final hasConnection = results.any((result) => result != ConnectivityResult.none);

      if (!hasConnection && !_wasOffline) {
        _wasOffline = true;
        SnackbarService.showOffline();
      } else if (hasConnection && _wasOffline) {
        _wasOffline = false;
        SnackbarService.showOnline();
      }
    });
  }
}