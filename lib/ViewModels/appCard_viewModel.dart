import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';

import '../../Models/appModel.dart';
import '../../Providers/app_provider.dart';
import '../../Providers/download_state_provider.dart';
import '../../Services/download_service.dart';
import '../Views/Widgets/AppStore/appCard.dart';

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
          } else {
            // cleanup APK if installed and version matches
            final fileName =
                '${widget.app.packageName}_${widget.app.version}.apk';
            await DownloadService.deleteApk(fileName);
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

  Future<void> _startDownload() async {
    final fileName = '${widget.app.packageName}_${widget.app.version}.apk';

    ref
        .read(downloadStateProvider.notifier)
        .updateDownload(
          widget.app.packageName,
          const DownloadState(progress: 0, status: DownloadTaskStatus.enqueued),
        );

    final taskId = await DownloadService.downloadApk(
      url: widget.app.downloadUrl,
      fileName: fileName,
      packageName: widget.app.packageName,
      onProgress: (progress, status) {
        ref
            .read(downloadStateProvider.notifier)
            .updateProgress(widget.app.packageName, progress, status);

        if (status == DownloadTaskStatus.complete) {
          _handleDownloadComplete();
        }
      },
    );

    if (taskId != null) {
      ref
          .read(downloadStateProvider.notifier)
          .updateDownload(
            widget.app.packageName,
            DownloadState(
              taskId: taskId,
              progress: 0,
              status: DownloadTaskStatus.running,
            ),
          );
    } else {
      if (mounted) {
        SnackbarService.showError("Failed to Start Download");
      }
      ref
          .read(downloadStateProvider.notifier)
          .removeDownload(widget.app.packageName);
    }
  }

  Future<void> _handleDownloadComplete() async {
    final state = ref.read(downloadStateProvider)[widget.app.packageName];
    final taskId = state?.taskId;

    if (taskId != null) {
      final filePath = await DownloadService.getDownloadedFilePath(taskId);

      if (filePath != null) {
        ref
            .read(downloadStateProvider.notifier)
            .setFilePath(widget.app.packageName, filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download complete! Installing...')),
          );
        }

        if (Platform.isAndroid) {
          await DownloadService.installApk(filePath);
          // add delay to allow package manager to update
          await Future.delayed(const Duration(seconds: 2));
          await _checkAppStatus();
        }

        ref
            .read(downloadStateProvider.notifier)
            .removeDownload(widget.app.packageName);
      }
    }
  }

  Future<void> _cancelDownload() async {
    final downloadState = ref.read(
      downloadStateProvider,
    )[widget.app.packageName];
    if (downloadState?.taskId != null) {
      await DownloadService.cancelDownload(downloadState!.taskId!);
      ref
          .read(downloadStateProvider.notifier)
          .removeDownload(widget.app.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(refreshTriggerProvider, (previous, next) {
      if (!Platform.isIOS) {
        _checkAppStatus();
      }
    });

    // FIX 4: Optimization using select
    // we only watch the specific entry for this package to avoid rebuilding
    // all cards when one updates.
    final downloadState = ref.watch(
      downloadStateProvider.select((state) => state[widget.app.packageName]),
    );

    return AppInfoCardUI(
      app: widget.app,
      isChecking: _isChecking,
      isInstalled: _isInstalled,
      updateAvailable: _updateAvailable,
      installedVersion: _installedVersion,
      isActive: widget.app.isActive,
      downloadState: downloadState,
      onDownload: _startDownload,
      onCancelDownload: _cancelDownload,
      onUninstall: () async {
        await InstalledApps.uninstallApp(widget.app.packageName);
      },
      onOpenApp: () => InstalledApps.startApp(widget.app.packageName),
    );
  }
}
