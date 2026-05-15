import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Managers/AuthWrapper.dart';
import 'Providers/app_provider.dart';
import 'Services/bootstrap_service.dart';
import 'Services/snackBar_Service.dart';
import 'Themes/AppTheme.dart';
import 'Utils/Dimensions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MNiveshCentralApp()));
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

    // kick off all init work after the first frame is drawn,
    // so the native splash disappears as fast as possible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(BootstrapService.runCritical());
      unawaited(BootstrapService.runDeferred());
    });
  }

  @override
  void dispose() {
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
            // only init SizeUtil if orientation actually changes to save cpu cycles
            if (_lastOrientation != orientation) {
              _lastOrientation = orientation;
              SizeUtil.init(context);
            }
            return child!;
          },
        );
      },
      home: const AuthWrapper(),
    );
  }
}
