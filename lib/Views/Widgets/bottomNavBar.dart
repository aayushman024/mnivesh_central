import 'dart:ui';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Hardcoded professional palette
    const Color darkBg = Color(0xFF020617); // Deepest slate/black
    const Color lightBg = Colors.white;
    final Color activeBlue = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

    return Container(
      // Increased height via decoration constraints and padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? darkBg : lightBg).withOpacity(0.0),
            (isDark ? darkBg : lightBg).withOpacity(0.8),
            (isDark ? darkBg : lightBg),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32), // Smoother, larger corner
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            // Forces the bar to be taller while keeping content centered
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: (isDark ? darkBg : lightBg).withOpacity(isDark ? 0.92 : 0.95),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                // Increased padding for better ergonomics and height
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      label: "Attendance",
                      icon: Icons.fingerprint,
                      activeIcon: Icons.fingerprint,
                      isActive: currentIndex == 0,
                      color: activeBlue,
                      onTap: () => onTap(0),
                    ),
                    _NavItemWithBadge(
                      label: "Modules",
                      icon: Icons.view_module_rounded,
                      activeIcon: Icons.view_module_rounded,
                      isActive: currentIndex == 1,
                      color: activeBlue,
                      updateCount: updateCount,
                      onTap: () => onTap(1),
                    ),
                    _NavItem(
                      label: "Store",
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront,
                      isActive: currentIndex == 2,
                      color: activeBlue,
                      onTap: () => onTap(2),
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
          vertical: 14, // Taller touch area
        ),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(isDark ? 0.12 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
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
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.4,
                ),
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
      label: Text('$updateCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFEF4444), // Consistent professional red
      offset: const Offset(10, -6),
      child: child,
    );
  }
}