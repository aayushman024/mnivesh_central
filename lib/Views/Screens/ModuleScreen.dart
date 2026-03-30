import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../Utils/ModuleTransitionAnimation.dart';
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

  // Splits text into spans to highlight the active search query
  TextSpan _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) return TextSpan(text: text, style: style);

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            backgroundColor: Colors.amber.withOpacity(0.4),
            color: style.color,
          ),
        ),
      );

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);

    final double spacing = 12.sdp;
    final double padding = 20.sdp;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = _getColumnCount(screenWidth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredModules = appModules.where((module) {
      final query = _searchQuery.toLowerCase();
      return module.title.toLowerCase().contains(query) ||
          module.description.toLowerCase().contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyle.light.small(),
              decoration: InputDecoration(
                hintText: "Search Modules...",
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

        if (filteredModules.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                "No modules found",
                style: AppTextStyle.normal.normal(
                  isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModuleCard(
                  context: context,
                  item: filteredModules[index],
                  searchQuery: _searchQuery,
                ),
                childCount: filteredModules.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: 180.sdp,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required ModuleItem item,
    required String searchQuery,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String heroTag = 'module_card_${item.title}';

    Widget card = Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
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
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (ctx, anim, _) =>
                          ModuleHeroScreen(item: item),
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (ctx, anim, _, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  );
                }
              : () {
                  FocusScope.of(context).unfocus();
                  SnackbarService.showComingSoon();
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
                    color: isDark
                        ? item.baseColor.withOpacity(0.15)
                        : item.baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.sdp),
                  ),
                  child: Icon(item.icon, color: item.baseColor, size: 28.sdp),
                ),
                SizedBox(height: 16.sdp),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: _buildHighlightedText(
                    item.title,
                    searchQuery,
                    AppTextStyle.bold.normal(
                      isDark ? Colors.white : const Color(0xFF0F1115),
                    ),
                  ),
                ),
                SizedBox(height: 6.sdp),
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: _buildHighlightedText(
                      item.description,
                      searchQuery,
                      AppTextStyle.light.small(
                        isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (item.targetScreen != null) {
      card = Hero(
        tag: heroTag,
        flightShuttleBuilder: (_, anim, _, fromCtx, _) {
          final isDarkFrom = Theme.of(fromCtx).brightness == Brightness.dark;
          return Material(
            color:
                Theme.of(fromCtx).cardTheme.color ??
                Theme.of(fromCtx).colorScheme.surface,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(28.sdp),
                decoration: BoxDecoration(
                  color: isDarkFrom
                      ? item.baseColor.withOpacity(0.15)
                      : item.baseColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28.sdp),
                ),
                child: Icon(item.icon, color: item.baseColor, size: 56.sdp),
              ),
            ),
          );
        },
        child: card,
      );
    }

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
            style: AppTextStyle.extraBold.small(Colors.white),
          ),
          TextSpan(
            text: item.description,
            style: AppTextStyle.normal.small(Colors.white70),
          ),
        ],
      ),
      child: card,
    );
  }
}
