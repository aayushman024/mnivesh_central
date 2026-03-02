import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart'; // import app_links
import '../Widgets/home_drawer.dart';
import '../Widgets/bottomNavBar.dart';
import 'ModuleScreen.dart';
import 'StoreScreen.dart';
import 'AttendanceScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}