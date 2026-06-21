import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:mnivesh_central/features/modules_analytics/api/analytics_api_service.dart';
import 'package:mnivesh_central/core/api/api_client.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/features/modules/models/module_screen_data.dart';
import 'package:mnivesh_central/features/modules_analytics/providers/module_usage_provider.dart';
import 'package:mnivesh_central/core/services/bootstrap_service.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/modules/utils/module_transition_animation.dart';
import 'package:mnivesh_central/features/home/widgets/home_app_bar.dart';

class ModulesScreen extends ConsumerStatefulWidget {
  const ModulesScreen({super.key});

  @override
  ConsumerState<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends ConsumerState<ModulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _userDepartment;
  bool _isLoadingDept = true;

  @override
  void initState() {
    super.initState();
    _loadDept();
  }

  Future<void> _loadDept() async {
    await BootstrapService.ready;
    final dept = AuthManager.department;
    if (mounted) {
      setState(() {
        _userDepartment = dept;
        _isLoadingDept = false;
      });
    }
  }

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

  void _handleModuleTap(BuildContext context, ModuleItem item) {
    FocusScope.of(context).unfocus();

    if (item.targetScreen == null) {
      SnackbarService.showComingSoon();
      return;
    }

    unawaited(AnalyticsApiService.logModuleTap(item.title));
    unawaited(
        ref.read(recentModulesProvider.notifier).recordAndRefresh(item.title));

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => ModuleHeroScreen(item: item, sourcePrefix: 'modules_'),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
      final matchesSearch =
          module.title.toLowerCase().contains(query) ||
          module.description.toLowerCase().contains(query);

      final isAllowed =
          module.allowedDepartments.isEmpty ||
          (_userDepartment != null &&
              module.allowedDepartments.contains(_userDepartment!));

      return matchesSearch && isAllowed;
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

        if (!_isLoadingDept && filteredModules.isEmpty)
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
            sliver: Skeletonizer.sliver(
              enabled: _isLoadingDept,
              child: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildModuleCard(
                    context: context,
                    item: _isLoadingDept ? appModules.take(6).toList()[index] : filteredModules[index],
                    searchQuery: _searchQuery,
                  ),
                  childCount: _isLoadingDept ? 6 : filteredModules.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: 180.sdp,
                ),
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
    final favourites = ref.watch(favouritesProvider);
    final isLiked = favourites.contains(item.title);
    final String heroTag = 'module_card_modules_${item.title}';

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
          onTap: () => _handleModuleTap(context, item),
          borderRadius: BorderRadius.circular(16.sdp),
          child: Padding(
            padding: EdgeInsets.all(16.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    if(isLiked)
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          PhosphorIconsFill.heart,
                          color: Colors.redAccent,
                          size: 18.sdp,
                        ),
                      ),
                  ],
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
      enableFeedback: true,
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
