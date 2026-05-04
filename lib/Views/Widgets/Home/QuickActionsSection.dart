import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';

import '../../../API/analytics_api_service.dart';
import '../../../Models/moduleScreen_data.dart';
import '../../../Providers/module_usage_provider.dart';
import '../../../Services/snackBar_Service.dart';
import '../../../Utils/Dimensions.dart';
import '../../../Utils/ModuleTransitionAnimation.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SizeUtil.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(recentModulesProvider);
    final modules = state.modules;
    final isDefault = state.isDefault;

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
          if (modules.isEmpty)
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
                itemCount: modules.length > 6 ? 6 : modules.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
                itemBuilder: (context, index) {
                  final item = modules[index];
                  final isFirstRecent = index == 0 && !isDefault;
                  return _QuickActionCard(
                    item: item,
                    isDark: isDark,
                    isFirstRecent: isFirstRecent,
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
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.item,
    required this.isDark,
    this.isFirstRecent = false,
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
                if (isFirstRecent)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 2.sdp, horizontal: 6.sdp),
                    decoration: BoxDecoration(
                      color:item.baseColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4.sdp),
                    ),
                    child: Text(
                      'RECENTLY USED',
                      style: AppTextStyle.bold.custom(10.ssp, item.baseColor).copyWith(
                        letterSpacing: 0.5.ssp,
                      ),
                    ),
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
