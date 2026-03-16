import 'package:flutter/material.dart';
import 'package:mnivesh_central/Views/Screens/MarketingScreen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../Views/Screens/ModulesScreens/MFTransScreen.dart';

// defines a single module's config
class ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color baseColor;
  final Widget? targetScreen; // null triggers 'coming soon'

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
    title: "MF Transaction",
    description:
        "Process purchases, redemptions, switches, and systematic investments.",
    icon: PhosphorIconsRegular.arrowsLeftRight,
    baseColor: Colors.blueAccent,
    targetScreen: const MfTransactionScreen(),
  ),
  ModuleItem(
    title: "Marketing",
    description: "Manage your marketing campaigns.",
    icon: PhosphorIconsRegular.megaphone,
    baseColor: Colors.purpleAccent,
    targetScreen: const MarketingScreen(),
  ),
  ModuleItem(
    title: "Calculators",
    description: "Calculate the future value of your investments",
    icon: PhosphorIconsRegular.calculator,
    baseColor: Colors.green,
    //targetScreen: const MarketingScreen(),
  ),
  ModuleItem(
    title: "Leaderboard",
    description: "Performance overview for FY2025-2026",
    icon: PhosphorIconsRegular.ranking,
    baseColor: Colors.orangeAccent,
    //targetScreen: const MarketingScreen(),
  ),
  ModuleItem(
    title: "Route Management",
    description: "Create, view, track, and manage routes for field employees.",
    icon: PhosphorIconsRegular.mapPin,
    baseColor: Colors.redAccent,
  ),
  ModuleItem(
    title: "Links",
    description: "Handy company links",
    icon: PhosphorIconsRegular.link,
    baseColor: Colors.deepPurpleAccent,
    //targetScreen: const MarketingScreen(),
  ),
];
