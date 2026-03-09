import 'dart:async';

import 'package:app_links/app_links.dart'; // import app_links
import 'package:flutter/material.dart';

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
    if (uri.scheme == 'mniveshcentral' && uri.host == 'store') {
      if (mounted) {
        setState(() {
          _currentIndex = 2; // switch to store tab
        });
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
