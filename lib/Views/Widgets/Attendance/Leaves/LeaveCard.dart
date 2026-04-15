import 'package:flutter/material.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Models/moduleScreen_data.dart';
import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../Utils/ModuleTransitionAnimation.dart';

class LeaveCard extends StatelessWidget {
  final ModuleItem? item;
  const LeaveCard({this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final leaveModule = appModules.firstWhere(
          (m) => m.title.contains("Leave"),
      orElse: () => appModules.first, // Fallback
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
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
          borderRadius: BorderRadius.circular(16.sdp),
          onTap: () {
            //SnackbarService.showComingSoon();
            leaveModule.targetScreen != null ?
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (ctx, anim, _) =>
                    ModuleHeroScreen(item: leaveModule),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (ctx, anim, _, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            ) : SnackbarService.showComingSoon();
          },
          child: Padding(
            padding: EdgeInsets.all(16.sdp),
            child: Row(
              children: [
                // ICON
                Container(
                  padding: EdgeInsets.all(14.sdp),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.indigo.withOpacity(0.15)
                        : Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14.sdp),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.calendarDots,
                    color: Colors.indigo,
                    size: 28.sdp,
                  ),
                ),

                SizedBox(width: 16.sdp),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Leave Management",
                        style: AppTextStyle.bold.normal(
                          isDark
                              ? Colors.white
                              : const Color(0xFF0F1115),
                        ),
                      ),
                      SizedBox(height: 6.sdp),
                      Text(
                        "View and apply your leaves",
                        style: AppTextStyle.light.small(
                          isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // ARROW
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 20.sdp,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}