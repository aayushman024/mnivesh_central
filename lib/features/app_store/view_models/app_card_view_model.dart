import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mnivesh_central/features/app_store/models/app_model.dart';
import 'package:mnivesh_central/features/app_store/providers/app_provider.dart';
import 'package:mnivesh_central/core/services/analytics_service.dart';
import 'package:mnivesh_central/features/app_store/widgets/app_card.dart';

class AppInfoCardContainer extends ConsumerStatefulWidget {
  final AppModel app;

  const AppInfoCardContainer({super.key, required this.app});

  @override
  ConsumerState<AppInfoCardContainer> createState() =>
      _AppInfoCardContainerState();
}

class _AppInfoCardContainerState extends ConsumerState<AppInfoCardContainer>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _isInstalled = false;
  bool _updateAvailable = false;
  String? _installedVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppStatus();
    }
  }

  Future<void> _checkAppStatus() async {
    if (!mounted) return;

    bool installed = false;
    String? currentVersion;
    bool updateNeeded = false;

    // bail out early on iOS since installed_apps plugin doesn't support it
    // and Apple will reject querying device packages anyway
    if (Platform.isAndroid) {
      final isInstalled = await InstalledApps.isAppInstalled(
        widget.app.packageName,
      );
      if (isInstalled == true) {
        installed = true;
        AppInfo? appInfo = await InstalledApps.getAppInfo(
          widget.app.packageName,
        );
        if (appInfo != null) {
          currentVersion = appInfo.versionName;
          if (currentVersion != widget.app.version) {
            updateNeeded = true;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isInstalled = installed;
        _updateAvailable = updateNeeded;
        _installedVersion = currentVersion;
        _isChecking = false;
      });
    }
  }

  Future<void> _redirectToPlayStore() async {
    if (_updateAvailable) {
      await AnalyticsService.logAppUpdateClicked(
        appName: widget.app.appName,
        packageName: widget.app.packageName,
        targetVersion: widget.app.version,
        installedVersion: _installedVersion,
      );
    } else {
      await AnalyticsService.logAppInstallClicked(
        appName: widget.app.appName,
        packageName: widget.app.packageName,
        version: widget.app.version,
      );
    }

    final playStoreUri = Uri.parse(
      "https://play.google.com/store/apps/details?id=${widget.app.packageName}",
    );

    try {
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
        SnackbarService.showError("Could not open Play Store");
      }
    } catch (e) {
      SnackbarService.showError("Error opening Play Store link: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(refreshTriggerProvider, (previous, next) {
      if (!Platform.isIOS) {
        _checkAppStatus();
      }
    });

    return AppInfoCardUI(
      app: widget.app,
      isChecking: _isChecking,
      isInstalled: _isInstalled,
      updateAvailable: _updateAvailable,
      installedVersion: _installedVersion,
      isActive: widget.app.isActive,
      onDownload: _redirectToPlayStore,
      onUninstall: () async {
        await InstalledApps.uninstallApp(widget.app.packageName);
      },
      onOpenApp: () => InstalledApps.startApp(widget.app.packageName),
    );
  }
}
