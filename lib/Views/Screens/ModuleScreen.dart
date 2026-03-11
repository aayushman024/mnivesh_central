import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Utils/Dimensions.dart';
import '../Widgets/homeAppBar.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // filter modules based on the active query
    final filteredModules = appModules.where((module) {
      final query = _searchQuery.toLowerCase();
      return module.title.toLowerCase().contains(query) ||
          module.description.toLowerCase().contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),

        // search bar sliver
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(fontSize: 14.ssp),
              decoration: InputDecoration(
                hintText: "Search modules...",
                prefixIcon: Icon(CupertinoIcons.search, size: 20.sdp),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.sdp),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.sdp),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.sdp),
                  borderSide: BorderSide.none,
                ),

                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[200],

                contentPadding: EdgeInsets.symmetric(vertical: 14.sdp),
              ),
            ),
          ),
        ),

        // handle empty state cleanly to avoid grid errors
        if (filteredModules.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                "No modules found",
                style: TextStyle(
                  fontSize: 16.ssp,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildModuleCard(
                  context: context,
                  item: filteredModules[index],
                );
              }, childCount: filteredModules.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: 180,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required ModuleItem item,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // wrapping in Tooltip to natively handle long press + rich text
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      padding: EdgeInsets.all(12.sdp),
      margin: EdgeInsets.symmetric(horizontal: 24.sdp),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.black87,
        borderRadius: BorderRadius.circular(8.sdp),
      ),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${item.title}\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.ssp,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: item.description,
            style: TextStyle(fontSize: 12.ssp, color: Colors.white70),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          // grab surface color from theme
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.sdp),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
          ),
          // disable shadows on dark mode
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.targetScreen != null
                ? () {
                    // drop keyboard before navigating to prevent overlay issues
                    FocusScope.of(context).unfocus();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => item.targetScreen!,
                      ),
                    );
                  }
                : () {
                    FocusScope.of(context).unfocus();
                    _showComingSoon(context);
                  },
            borderRadius: BorderRadius.circular(16.sdp),
            child: Padding(
              padding: EdgeInsets.all(16.sdp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.sdp),
                    decoration: BoxDecoration(
                      // dynamic bg opacity based on mode
                      color: isDark
                          ? item.baseColor.withOpacity(0.15)
                          : item.baseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.sdp),
                    ),
                    child: Icon(item.icon, color: item.baseColor, size: 28.sdp),
                  ),
                  SizedBox(height: 16.sdp),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16.ssp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F1115),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.sdp),
                  Expanded(
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12.ssp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
