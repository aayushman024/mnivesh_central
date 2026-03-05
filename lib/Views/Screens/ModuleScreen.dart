import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mnivesh_central/Views/Screens/ModulesScreens/MFTransScreen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Utils/Dimensions.dart';
import '../Widgets/homeAppBar.dart';
// Note: Removed the neumorphic_button import since we are using a custom card for the redesign.

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  // tweaked to show 2 items per row on mobile, scaling up for larger screens
  int _getColumnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    return 2;
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Coming soon!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(16.sdp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.sdp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double spacing = 16.sdp;
    final double padding = 20.sdp;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = _getColumnCount(screenWidth);

    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            delegate: SliverChildListDelegate([
              _buildModuleCard(
                context: context,
                title: "MF Transaction",
                description: "Buy, sell, or switch mutual funds instantly.",
                icon: PhosphorIconsRegular.arrowsLeftRight,
                iconColor: Colors.blueAccent,
                bgColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const MfTransactionScreen(),
                    ),
                  );
                },
              ),
              // added a dummy tile to visualize the 2-in-a-row layout
              _buildModuleCard(
                context: context,
                title: "Portfolio",
                description: "Track your investments and current valuation.",
                icon: PhosphorIconsRegular.chartPieSlice,
                iconColor: Colors.purpleAccent,
                bgColor: Colors.purple.withOpacity(0.1),
                onTap: () => _showComingSoon(context),
              ),
            ]),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: 180, // increased to fit the new description area
            ),
          ),
        ),
      ],
    );
  }

  // local widget for the redesigned cards
  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          // consider grabbing this from Theme.of(context) if supporting dark mode
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // wrapped the icon in a colored container.
            // you can easily drop this Container and use Image.asset('assets/custom_illustration.png', height: 48) if you prefer actual images.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
