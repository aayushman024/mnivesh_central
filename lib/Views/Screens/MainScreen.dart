import 'package:flutter/material.dart';
import '../Widgets/home_drawer.dart';
import '../Widgets/bottomNavBar.dart'; // Bringing in the custom bottom nav
import 'ModuleScreen.dart';
import 'StoreScreen.dart';
import 'AttendanceScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

  final List<Widget> _screens = [
    const AttendanceScreen(),
    const ModulesScreen(),
    const StoreScreen(),
  ];

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