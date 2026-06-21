import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:mnivesh_central/features/modules_analytics/api/analytics_api_service.dart';
import 'package:mnivesh_central/features/modules/models/module_screen_data.dart';
import 'package:mnivesh_central/features/modules_analytics/providers/module_usage_provider.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/modules/utils/module_transition_animation.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  void _handleModuleTap(
      BuildContext context, WidgetRef ref, ModuleItem item) {
    FocusScope.of(context).unfocus();

    if (item.targetScreen == null) {
      SnackbarService.showComingSoon();
      return;
    }

    unawaited(AnalyticsApiService.logModuleTap(item.title));
    unawaited(
        ref.read(recentModulesProvider.notifier).recordAndRefresh(item.title));

    if (item.parentModuleTitle != null) {
      // Find parent module
      final parent = appModules.firstWhere(
        (m) => m.title == item.parentModuleTitle,
        orElse: () => throw Exception('Parent module not found: ${item.parentModuleTitle}'),
      );

      // Navigate to parent first using morph animation
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => ModuleHeroScreen(item: parent, sourcePrefix: 'home_'),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

      // Wait for morph to settle, then automatically push sub-module
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (context.mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (ctx, anim, _) => item.targetScreen!,
              transitionDuration: const Duration(milliseconds: 450),
              transitionsBuilder: (ctx, anim, _, child) {
                final curved = CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeInOut,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          );
        }
      });
    } else {
      // Standard module navigation
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => ModuleHeroScreen(item: item, sourcePrefix: 'home_'),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SizeUtil.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentState = ref.watch(recentModulesProvider);
    final favourites = ref.watch(favouritesProvider);

    final allPossibleModules = [...appModules, ...subModules];

    // Compute the custom sorted list:
    // 1. Latest Used (most recent first in state.modules)
    ModuleItem? latestUsed;
    if (recentState.modules.isNotEmpty && !recentState.isDefault) {
      latestUsed = recentState.modules.first;
    }

    // 2. Liked modules (excluding latestUsed if it is liked)
    final likedModules = allPossibleModules
        .where((m) => favourites.contains(m.title) && m.title != latestUsed?.title)
        .toList();

    // 3. Most used modules (excluding latestUsed and likedModules)
    final mostUsed = recentState.mostUsedModules
        .where((m) => m.title != latestUsed?.title && !favourites.contains(m.title))
        .toList();

    // Combine them!
    final List<ModuleItem> combined = [];
    if (latestUsed != null) {
      combined.add(latestUsed);
    }
    combined.addAll(likedModules);
    combined.addAll(mostUsed);

    // If combined is empty, fall back to defaults
    final List<ModuleItem> finalModules = combined.isEmpty ? recentState.modules : combined;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.sdp, vertical: 15.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Text(
                'QUICK ACTIONS',
                style: AppTextStyle.bold
                    .custom(16.ssp)
                    .copyWith(letterSpacing: 2.ssp),
              ),
              SizedBox(width: 10.sdp),
              Expanded(
                child: Container(
                  height: 1.sdp,
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(40),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.sdp),

          // ── Horizontal scrolling module cards ───────────────────
          if (finalModules.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.sdp),
              child: Center(
                child: Text(
                  'Your recently & most used modules will appear here',
                  style: AppTextStyle.normal.small(
                    isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 170.sdp,
              child: ListView.separated(
                clipBehavior: Clip.none,
                padding: EdgeInsets.only(bottom: 16.sdp, top: 4.sdp, right: 6.sdp),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: finalModules.length > 6 ? 6 : finalModules.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
                itemBuilder: (context, index) {
                  final item = finalModules[index];
                  final isFirstRecent = index == 0 && !recentState.isDefault && latestUsed?.title == item.title;
                  final isLiked = favourites.contains(item.title);
                  return _QuickActionCard(
                    item: item,
                    isDark: isDark,
                    isFirstRecent: isFirstRecent,
                    isLiked: isLiked,
                    onTap: () => _handleModuleTap(context, ref, item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Quick Action card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final ModuleItem item;
  final bool isDark;
  final bool isFirstRecent;
  final bool isLiked;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.item,
    required this.isDark,
    this.isFirstRecent = false,
    required this.isLiked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = 240.sdp;

    Widget card = Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.sdp),
          child: Padding(
            padding: EdgeInsets.all(14.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.sdp),
                      decoration: BoxDecoration(
                        color: isDark
                            ? item.baseColor.withOpacity(0.15)
                            : item.baseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.sdp),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.baseColor,
                        size: 22.sdp,
                      ),
                    ),
                    SizedBox(width: 10.sdp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 10.sdp),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.bold.normal(
                              isDark ? Colors.white : const Color(0xFF0F1115),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.sdp),
                // Description
                Expanded(
                  child: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.light.custom(12.ssp).copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                  ),
                ),
                SizedBox(height: 10.sdp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isFirstRecent)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 2.sdp, horizontal: 6.sdp),
                        decoration: BoxDecoration(
                          color: item.baseColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4.sdp),
                        ),
                        child: Text(
                          'RECENTLY USED',
                          style: AppTextStyle.bold.custom(10.ssp, item.baseColor).copyWith(
                            letterSpacing: 0.5.ssp,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (isLiked)
                      Icon(
                        PhosphorIconsFill.heart,
                        color: Colors.redAccent,
                        size: 16.sdp,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Hero for transition animation (same tag as ModulesScreen)
    if (item.targetScreen != null) {
      card = Hero(
        tag: 'module_card_home_${item.title}',
        flightShuttleBuilder: (_, anim, _, fromCtx, _) {
          final isDarkFrom =
              Theme.of(fromCtx).brightness == Brightness.dark;
          return Material(
            color: Theme.of(fromCtx).cardTheme.color ??
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
                child:
                    Icon(item.icon, color: item.baseColor, size: 56.sdp),
              ),
            ),
          );
        },
        child: card,
      );
    }

    return card;
  }
}
