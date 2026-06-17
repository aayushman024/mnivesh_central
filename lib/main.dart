import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'Managers/AuthManager.dart';
import 'Managers/AuthWrapper.dart';
import 'Providers/app_provider.dart';
import 'Providers/profile_image_provider.dart';
import 'Services/bootstrap_service.dart';
import 'Services/location_sharing_service.dart';
import 'Services/snackBar_Service.dart';
import 'Themes/AppTheme.dart';
import 'Utils/Dimensions.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final view = binding.platformDispatcher.views.first;

  void launch() {
    SizeUtil.initFromView(view);
    runApp(const ProviderScope(child: MNiveshCentralApp()));
  }

  if (view.physicalSize != Size.zero) {
    // View already has real dimensions (e.g. hot-restart, debug attach).
    launch();
  } else {
    // Release cold-start: physicalSize is not yet available synchronously.
    // Wait for the platform to report the first real metrics before painting.
    binding.platformDispatcher.onMetricsChanged = () {
      // Clear immediately — orientation changes are handled by OrientationBuilder.
      binding.platformDispatcher.onMetricsChanged = null;
      launch();
    };
  }
}

class MNiveshCentralApp extends ConsumerStatefulWidget {
  const MNiveshCentralApp({super.key});

  @override
  ConsumerState<MNiveshCentralApp> createState() => _MNiveshCentralAppState();
}

class _MNiveshCentralAppState extends ConsumerState<MNiveshCentralApp>
    with WidgetsBindingObserver {
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    LocationSharingService.initListeners();

    // kick off all init work after the first frame is drawn,
    // so the native splash disappears as fast as possible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BootstrapService.runCritical().then((_) {
        ref.read(profileImageProvider.notifier).init(AuthManager.photoUrl);
      });
      unawaited(BootstrapService.runDeferred());
    });
  }

  @override
  void dispose() {
    LocationSharingService.disposeListeners();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(BootstrapService.runCritical());
      unawaited(BootstrapService.runDeferred());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final view = View.of(context);
    SizeUtil.initFromView(view);

    return MaterialApp(
      title: 'mNivesh Central',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: SnackbarService.navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OrientationBuilder(
          builder: (context, orientation) {
            // Refresh SizeUtil when the view metrics change, especially on rotation.
            if (_lastOrientation != orientation) {
              _lastOrientation = orientation;
              SizeUtil.initFromView(View.of(context));
            }
            return child!;
          },
        );
      },
      home: const AuthWrapper(),
    );
  }
}
