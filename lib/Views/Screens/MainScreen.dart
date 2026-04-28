import 'dart:async';

import 'package:app_links/app_links.dart'; // import app_links
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:mnivesh_central/Services/analytics_service.dart';
import 'package:mnivesh_central/ViewModels/announcement_viewModel.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Providers/app_provider.dart';
import '../../Utils/ModuleTransitionAnimation.dart';
import '../Widgets/bottomNavBar.dart';
import '../Widgets/home_drawer.dart';
import 'AnnouncementModalScreen.dart';
import 'AttendanceScreen.dart';
import 'ModuleScreen.dart';
import 'StoreScreen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int? pageIndex;

  const MainScreen({this.pageIndex, super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex = widget.pageIndex ?? 1;
  int? _lastTrackedIndex;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    //  ref.read(announcementViewModelProvider.notifier).fetchAnnouncements();
      _trackCurrentScreen(source: 'initial_load');
    });
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // handle cold start (app killed)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _processDeepLink(initialUri);
    }

    // handle warm start (app in background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _processDeepLink(uri);
    });
  }

  void _processDeepLink(Uri uri) {
    if (uri.scheme == 'mniveshcentral') {
      if (uri.host == 'app' && uri.path == '/announcements') {
        if (mounted) {
          AnnouncementModal.show(
            context,
            initialItems: ref.read(announcementViewModelProvider).items,
          );
        }
      } else if (uri.host == 'store') {
        if (mounted) {
          _setCurrentIndex(2, source: 'deep_link');
        }
      } else if (uri.host == 'module') {
        // Deep link format: mniveshcentral://module?name=Callyn%20Analytics
        final moduleName = uri.queryParameters['name'];
        if (moduleName != null && mounted) {
          try {
            final module = appModules.firstWhere(
                  (m) => m.title.toLowerCase() == moduleName.toLowerCase(),
            );

            if (module.targetScreen != null) {
              // 1. Switch bottom nav to the modules tab underneath
              _setCurrentIndex(1, source: 'deep_link');

              // 2. Push the Hero Animation Screen
              // We use PageRouteBuilder for a seamless transition
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ModuleHeroScreen(item: module),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          } catch (e) {
            debugPrint("DeepLink Error: Module '$moduleName' not found.");
            SnackbarService.showError("Module doesn't exist");
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateCount = ref.watch(updateCountProvider);
    final screens = const <Widget>[
      AttendanceScreen(),
      ModulesScreen(),
      StoreScreen(),
    ];

    return Scaffold(
      // floatingActionButton: _currentIndex == 0 ? LeaveFloatingActionButton(
      // ) : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const HomeDrawer(),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => _setCurrentIndex(index, source: 'bottom_nav'),
        updateCount: updateCount,
      ),
    );
  }

  void _setCurrentIndex(int index, {required String source}) {
    final changed = _currentIndex != index;
    if (changed) {
      setState(() => _currentIndex = index);
    }
    if (changed || _lastTrackedIndex == null) {
      _trackCurrentScreen(source: source, indexOverride: index);
    }
  }

  void _trackCurrentScreen({
    required String source,
    int? indexOverride,
  }) {
    final index = indexOverride ?? _currentIndex;
    _lastTrackedIndex = index;

    switch (index) {
      case 0:
        unawaited(
          AnalyticsService.logScreenView(
            screenName: 'attendance_screen',
            screenClass: 'AttendanceScreen',
          ),
        );
        break;
      case 1:
        unawaited(
          AnalyticsService.logScreenView(
            screenName: 'modules_screen',
            screenClass: 'ModulesScreen',
          ),
        );
        break;
      case 2:
        unawaited(
          Future.wait([
            AnalyticsService.logScreenView(
              screenName: 'store_screen',
              screenClass: 'StoreScreen',
            ),
            AnalyticsService.logStoreOpened(source: source),
          ]),
        );
        break;
    }
  }
}
