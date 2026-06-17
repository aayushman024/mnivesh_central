import 'package:flutter/material.dart';
import 'package:mnivesh_central/Views/Screens/InvestwellReportScreen.dart';
import 'package:mnivesh_central/Views/Screens/MarketingScreen.dart';
import 'package:mnivesh_central/Views/Screens/RouteManagement/RouteManagementDashboardScreen.dart';
import 'package:mnivesh_central/Views/Screens/RouteManagement/field_executive_tracking_screen.dart';
import 'package:mnivesh_central/Views/Screens/RouteManagement/view_route_details_screen.dart';
import 'package:mnivesh_central/Views/Screens/RouteManagement/visit_details_screen.dart';
import 'package:mnivesh_central/Views/Screens/RouteManagement/add_task_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../Views/Screens/CallynAnalyticsScreen.dart';
import '../Views/Screens/MFTransaction/MFTransScreen.dart';
import '../Views/Screens/ModulesAnalyticsScreen.dart';

// defines a single module's config
class ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color baseColor;
  final Widget? targetScreen;
  final List<String> allowedDepartments;
  final String? parentModuleTitle;

  ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.baseColor,
    this.targetScreen,
    this.allowedDepartments = const [],
    this.parentModuleTitle,
  });
}


// central list of all modules. add/remove here to update UI instantly
final List<ModuleItem> appModules = [
  ModuleItem(
    title: "Leave Management",
    description: "View and manage your leaves",
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
    title: "Marketing Templates",
    description: "Manage your marketing campaigns.",
    icon: PhosphorIconsRegular.megaphone,
    baseColor: Colors.purpleAccent,
    targetScreen: const MarketingScreen(),
  ),
  ModuleItem(
    title: "Route Management",
    description: "Create, view, track, and manage routes for field employees.",
    icon: PhosphorIconsRegular.mapPin,
    baseColor: Colors.redAccent,
    targetScreen: RouteManagementDashboard(),
  ),
  ModuleItem(
    title: "Investwell Reports",
    description: "View the Capital Gain & Portfolio Reports of your clients",
    icon: PhosphorIconsRegular.browsers,
    baseColor: Colors.lightBlueAccent,
    // targetScreen: InvestwellReportScreen()
  ),
  ModuleItem(
    title: "Callyn Analytics",
    description: "View the in-detail call log analysis of the team.",
    icon: PhosphorIconsRegular.phone,
    baseColor: Colors.green,
    targetScreen: const CallynAnalyticsScreen(),
    allowedDepartments: ["Management", "IT Desk"]
  ),
  ModuleItem(
    title: "Modules Analytics",
    description:
        "View the in-detail access log analysis of the modules in mNivesh Central.",
    icon: PhosphorIconsRegular.presentationChart,
    baseColor: Colors.blueAccent,
    targetScreen: const ModulesAnalyticsScreen(),
      allowedDepartments: ["Management", "IT Desk"]
  ),
  ModuleItem(
    title: "CC Health Checkpoints",
    description: "View the latest health status of deployed apps",
    icon: PhosphorIconsRegular.shieldCheck,
    baseColor: Colors.deepPurple,
  ),
  ModuleItem(
    title: "Leaderboard",
    description: "Performance overview for FY2025-2026",
    icon: PhosphorIconsRegular.ranking,
    baseColor: Colors.orangeAccent,
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

// sub modules for specific sub-actions
final List<ModuleItem> subModules = [
  ModuleItem(
    title: "Track Field Executives",
    description: "Monitor real-time locations and delays across your field force.",
    icon: PhosphorIconsRegular.mapPinLine,
    baseColor: const Color(0xFF38D39F),
    targetScreen: const FieldExecutiveTrackingScreen(),
    parentModuleTitle: "Route Management",
  ),
  ModuleItem(
    title: "Visit Details",
    description: "See a consolidated view of upcoming client visits and status.",
    icon: PhosphorIconsRegular.eye,
    baseColor: Colors.indigo,
    targetScreen: const VisitDetailsScreen(),
    parentModuleTitle: "Route Management",
  ),
  ModuleItem(
    title: "Add New Visit",
    description: "Add client visits, preferred timeslots and visit objectives.",
    icon: PhosphorIconsRegular.plusCircle,
    baseColor: Colors.green,
    targetScreen: const AddTaskScreen(),
    parentModuleTitle: "Route Management",
  ),  ModuleItem(
    title: "View Route Details",
    description:  'View exact route details, distances, and ETAs for each client',
    icon: PhosphorIconsRegular.path,
    baseColor: Colors.orange,
    targetScreen: const ViewRouteDetailsScreen(),
    parentModuleTitle: "Route Management",
  ),
];

