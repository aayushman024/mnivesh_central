import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mnivesh_central/Services/CustomHapticService.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Utils/Dimensions.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int updateCount;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.updateCount = 0,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    /// Use theme colors instead of hardcoded
    final Color bg = theme.scaffoldBackgroundColor;
    final Color surface = theme.colorScheme.surface;

    /// Active color from theme
    final Color activeBlue =
    isDark ? theme.colorScheme.primary : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withOpacity(0.0),
            bg.withOpacity(0.8),
            bg,
          ],
        ),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.sdp),
          topRight: Radius.circular(32.sdp),
        ),

        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

          child: Container(
            constraints: const BoxConstraints(minHeight: 50),

            decoration: BoxDecoration(
              /// Proper surface color
              color: surface.withOpacity(isDark ? 0.95 : 0.98),

              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  width: 1.2.sdp,
                ),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    isDark ? 0.5 : 0.08,
                  ),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),

            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28.sdp,
                  vertical: 10.sdp,
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      label: "Attendance",
                      icon: PhosphorIcons.fingerprint(),
                      activeIcon: PhosphorIcons.fingerprint(),
                      isActive: currentIndex == 0,
                      color: activeBlue,
                      onTap: (){
                        CustomHapticService.selection();
                        onTap(0);
                      },
                    ),

                    _NavItem(
                      label: "Modules",
                      icon: PhosphorIcons.stack(),
                      activeIcon: PhosphorIcons.stack(),
                      isActive: currentIndex == 1,
                      color: activeBlue,
                      onTap: (){
                        CustomHapticService.selection();
                        onTap(1);
                      },
                    ),

                    _NavItemWithBadge(
                      label: "Store",
                      icon: PhosphorIcons.storefront(),
                      activeIcon: PhosphorIcons.storefront(),
                      isActive: currentIndex == 2,
                      color: activeBlue,
                      updateCount: updateCount,
                      onTap: (){
                        CustomHapticService.selection();
                        onTap(2);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _NavItem and _NavItemWithBadge logic remains the same,
// but ensure _NavItem uses the updated padding for better tap targets.
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 22 : 14,
          vertical:14.sdp, // Taller touch area
        ),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(isDark ? 0.12 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(24.sdp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26, // Slightly larger icons
              color: isActive ? color : (isDark ? Colors.white38 : Colors.black38),
            ),
            if (isActive) ...[
              SizedBox(width:10.sdp),
              Text(
                label,
                style: AppTextStyle.extraBold.custom(15.ssp, color).copyWith(letterSpacing: -0.4)
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color color;
  final int updateCount;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.color,
    required this.updateCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = _NavItem(
      label: label,
      icon: icon,
      activeIcon: activeIcon,
      isActive: isActive,
      color: color,
      onTap: onTap,
    );

    if (updateCount <= 0) return child;

    return Badge(
      backgroundColor: const Color(0xFFEF4444), // Consistent professional red
      offset: const Offset(10, -6),
      smallSize: 10,
      child: child,
    );
  }
}