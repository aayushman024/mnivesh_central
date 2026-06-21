import 'dart:async';

import 'package:app_links/app_links.dart'; // import app_links
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/core/providers/profile_image_provider.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:mnivesh_central/core/services/analytics_service.dart';
import 'package:mnivesh_central/features/announcements/view_models/announcement_view_model.dart';
import 'package:mnivesh_central/features/home/screens/home_screen.dart';

import 'package:mnivesh_central/features/modules/models/module_screen_data.dart';
import 'package:mnivesh_central/features/app_store/providers/app_provider.dart';
import 'package:mnivesh_central/features/modules/utils/module_transition_animation.dart';
import 'package:mnivesh_central/features/daftar/widgets/leaves/leave_fab.dart';
import 'package:mnivesh_central/features/home/widgets/bottom_nav_bar.dart';
import 'package:mnivesh_central/features/home/widgets/home_drawer.dart';
import 'package:mnivesh_central/features/announcements/screens/announcement_modal_screen.dart';
import 'package:mnivesh_central/features/daftar/screens/attendance_screen.dart';
import 'package:mnivesh_central/features/modules/screens/module_screen.dart';
import 'package:mnivesh_central/features/route_management/screens/route_management_dashboard_screen.dart';
import 'package:mnivesh_central/features/app_store/screens/store_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int? pageIndex;

  const MainScreen({this.pageIndex, super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex = widget.pageIndex ?? 0;
  int? _lastTrackedIndex;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementViewModelProvider.notifier).fetchAnnouncements();
      ref.read(profileImageProvider.notifier).init(AuthManager.photoUrl);
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
          _setCurrentIndex(3, source: 'deep_link');
        }
      } else if (uri.host == 'module') {
        // Deep link format: mniveshcentral://module?name=Route%20Management?clientName={clientName}?t={timestamp}
        String? moduleName = uri.queryParameters['name'];
        String? clientName = uri.queryParameters['clientName'];
        String? timestampStr = uri.queryParameters['t'] ?? uri.queryParameters['timestamp'];

        if (moduleName != null) {
          if (moduleName.contains('?')) {
            final parts = moduleName.split('?');
            moduleName = parts[0];
            for (var part in parts.skip(1)) {
              if (part.startsWith('clientName=')) {
                clientName = Uri.decodeComponent(part.substring('clientName='.length));
              } else if (part.startsWith('t=')) {
                timestampStr = Uri.decodeComponent(part.substring('t='.length));
              } else if (part.startsWith('timestamp=')) {
                timestampStr = Uri.decodeComponent(part.substring('timestamp='.length));
              }
            }
          }
        }

        if (timestampStr != null) {
          final timestamp = int.tryParse(timestampStr);
          if (timestamp != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final ms = timestampStr.length <= 10 ? timestamp * 1000 : timestamp;
            final diff = (now - ms).abs();
            if (diff > 15000) {
              debugPrint('[DeepLink] Ignored stale deep link (diff: ${diff}ms, url t: $ms, now: $now)');
              return;
            }
          }
        }

        if (moduleName != null && mounted) {
          try {
            final module = appModules.firstWhere(
                  (m) => m.title.toLowerCase() == moduleName!.toLowerCase(),
            );

            if (module.targetScreen != null) {
              // 1. Switch bottom nav to the modules tab underneath
              _setCurrentIndex(2, source: 'deep_link');

              Widget targetScreen = module.targetScreen!;
              if (module.title == "Route Management" && clientName != null) {
                targetScreen = RouteManagementDashboard(clientName: clientName);
              }

              final customModule = ModuleItem(
                title: module.title,
                description: module.description,
                icon: module.icon,
                baseColor: module.baseColor,
                targetScreen: targetScreen,
                allowedDepartments: module.allowedDepartments,
                parentModuleTitle: module.parentModuleTitle,
              );

              // 2. Push the Hero Animation Screen
              // We use PageRouteBuilder for a seamless transition
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ModuleHeroScreen(item: customModule, sourcePrefix: 'modules_'),
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
      HomeScreen(),
      AttendanceScreen(),
      ModulesScreen(),
      StoreScreen(),
    ];

    return Scaffold(
      // floatingActionButton: _currentIndex == 1 ? LeaveFloatingActionButton(
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
            screenName: 'home_screen',
            screenClass: 'HomeScreen',
          ),
        );
        break;
      case 1:
        unawaited(
          AnalyticsService.logScreenView(
            screenName: 'attendance_screen',
            screenClass: 'AttendanceScreen',
          ),
        );
        break;
      case 2:
        unawaited(
          AnalyticsService.logScreenView(
            screenName: 'modules_screen',
            screenClass: 'ModulesScreen',
          ),
        );
        break;
      case 3:
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
