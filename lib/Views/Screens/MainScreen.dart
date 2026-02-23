import 'package:flutter/material.dart';
import '../Widgets/home_drawer.dart';
import 'ModuleScreen.dart';
import 'StoreScreen.dart';
import 'AttendanceScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AttendanceScreen(),
    const ModulesScreen(),
    const StoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),

      // Inject the custom drawer here
      drawer: const HomeDrawer(),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0F),
        selectedItemColor: const Color(0xFFD0BCFF),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.view_module), label: "Modules"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Store"),
        ],
      ),
    );
  }
}