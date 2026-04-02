import 'dart:async';

import 'package:app_links/app_links.dart'; // import app_links
import 'package:flutter/material.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:mnivesh_central/Views/Widgets/Attendance/LeaveFAB.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Utils/ModuleTransitionAnimation.dart';
import '../Widgets/bottomNavBar.dart';
import '../Widgets/home_drawer.dart';
import 'AttendanceScreen.dart';
import 'ModuleScreen.dart';
import 'StoreScreen.dart';

class MainScreen extends StatefulWidget {
  final int? pageIndex;

  const MainScreen({this.pageIndex, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = widget.pageIndex ?? 0;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final List<Widget> _screens = [
    const AttendanceScreen(),
    const ModulesScreen(),
    const StoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAppLinks();
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
      if (uri.host == 'store') {
        if (mounted) {
          setState(() {
            _currentIndex = 2; // switch to store tab
          });
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
              setState(() => _currentIndex = 1);

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
            // Handle error or show snackbar if module doesn't exist
          }
        }
      }
    }
  }

  @override
  void dispose() {
    // cleanup listener
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _currentIndex == 0 ? LeaveFloatingActionButton(
          onPressed: (){
            SnackbarService.showComingSoon();
          }
      ) : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const HomeDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
