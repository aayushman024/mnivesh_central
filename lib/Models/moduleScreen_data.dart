import 'package:flutter/material.dart';
import 'package:mnivesh_central/Views/Screens/MarketingScreen.dart';
import 'package:mnivesh_central/Views/Screens/TeamStatusScreen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../Views/Screens/CallynAnalyticsScreen.dart';
import '../Views/Screens/MFTransScreens/MFTransScreen.dart';

// defines a single module's config
class ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color baseColor;
  final Widget? targetScreen;

  ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.baseColor,
    this.targetScreen,
  });
}

// central list of all modules. add/remove here to update UI instantly
final List<ModuleItem> appModules = [
  ModuleItem(
    title: "Leave Management",
    description: "View and apply your leaves",
    icon: PhosphorIconsRegular.calendarDots,
    baseColor: Colors.indigo,
  ),
  ModuleItem(
    title: "MF Transaction Form",
    description:
        "Process purchases, redemptions, switches, and systematic investments.",
    icon: PhosphorIconsRegular.arrowsLeftRight,
    baseColor: Colors.blueAccent,
    targetScreen: const MfTransactionScreen(),
  ),
  ModuleItem(
    title: "Callyn Analytics",
    description: "View the in-detail call log analysis of the team.",
    icon: PhosphorIconsRegular.phone,
    baseColor: Colors.green,
    targetScreen: const CallynAnalyticsScreen(),
  ),
  ModuleItem(
    title: "Marketing Templates",
    description: "Manage your marketing campaigns.",
    icon: PhosphorIconsRegular.megaphone,
    baseColor: Colors.purpleAccent,
    targetScreen: const MarketingScreen(),
  ),
  ModuleItem(
    title: "Leaderboard",
    description: "Performance overview for FY2025-2026",
    icon: PhosphorIconsRegular.ranking,
    baseColor: Colors.orangeAccent,
  ),
  ModuleItem(
    title: "Route Management",
    description: "Create, view, track, and manage routes for field employees.",
    icon: PhosphorIconsRegular.mapPin,
    baseColor: Colors.redAccent,
  ),
  ModuleItem(
    title: "Feedback",
    description: "Give and view your feedbacks",
    icon: PhosphorIconsRegular.exam,
    baseColor: Colors.blueGrey,
  ),
  ModuleItem(
    title: "Calculators",
    description: "Calculate the future value of your investments",
    icon: PhosphorIconsRegular.calculator,
    baseColor: Colors.brown,
  ),
];
