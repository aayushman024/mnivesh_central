import 'package:flutter_riverpod/legacy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:mnivesh_central/core/api/api_service.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/core/services/analytics_service.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';

class LoginViewModel extends StateNotifier<bool> {
  LoginViewModel() : super(false);

  Future<void> handleLogin() async {
    if (state) return;

    state = true;

    try {
      await AnalyticsService.logLoginStarted();
      await AuthManager.markLoginFlowStarted();

      final authUrl = await ApiService.getZohoAuthUrl();

      if (authUrl == null || authUrl.isEmpty) {
        await AuthManager.clearPendingLoginFlow();
        await AnalyticsService.logLoginFailed('missing_auth_url');
        SnackbarService.showError("Unable to start login. Please try again.");
        return;
      }

      final url = Uri.parse(authUrl);

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await AuthManager.clearPendingLoginFlow();
        await AnalyticsService.logLoginFailed('launch_failed');
        SnackbarService.showError(
          "Could not open login page. Please try again.",
        );
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Login flow failed');
      await AuthManager.clearPendingLoginFlow();
      await AnalyticsService.logLoginFailed('request_exception');
      SnackbarService.showError(
        "Login failed. Check your connection and try again. $e",
      );
    } finally {
      state = false;
    }
  }
}

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, bool>((
  ref,
) {
  return LoginViewModel();
});
