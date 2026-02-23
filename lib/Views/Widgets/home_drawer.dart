import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Managers/AuthManager.dart';
import '../../Providers/app_provider.dart';
import '../Screens/TeamStatusScreen.dart';

class HomeDrawer extends ConsumerStatefulWidget {
  const HomeDrawer({super.key});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  String _userName = "User";
  String _userEmail = "Loading...";
  String _userDept = "Loading...";
  String _workPhone = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('UserName') ?? "User";
      _userEmail = prefs.getString('UserEmail') ?? "No email provided";
      _userDept = prefs.getString('user_department') ?? "N/A";
      _workPhone = prefs.getString('workPhone') ?? "N/A";
    });
  }

  String get _initials {
    if (_userName.isEmpty) return "U";
    final parts = _userName.trim().split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : parts[0][0].toUpperCase();
  }

  Future<void> _logout() async {
    await AuthManager.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the themeProvider directly so the switch updates immediately on tap.
    // Relying just on Theme.of(context).brightness can sometimes cause lag in the switch animation.
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    final colors = isDark ? _DarkColors() : _LightColors();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: colors.drawerBg,
      // Radius set for left-side drawer only
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(colors),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),

                // --- Preferences ---
                _buildToggleItem(
                  label: "Dark Mode",
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  tint: const Color(0xFF38BDF8), // Light Blue
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  colors: colors,
                ),

                // --- Management Section ---
                if (_userDept == "IT Desk" || _userDept == "Management") ...[
                  _buildActionItem(
                    label: "Team Status",
                    icon: Icons.insights_rounded,
                    tint: const Color(0xFFA5B4FC), // Indigo/Purple
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TeamStatusScreen()),
                      );
                    },
                  ),
                ],

                // --- Divider ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 32),
                  child: Divider(
                    color: colors.divider,
                    thickness: 1,
                  ),
                ),

                // --- Logout ---
                _buildActionItem(
                  label: "Logout",
                  icon: Icons.logout_rounded,
                  tint: const Color(0xFFF44336), // Red
                  isDestructive: true,
                  colors: colors,
                  onTap: _logout,
                ),

                const SizedBox(height: 24),
                _buildVersionItem("1.0.1", colors),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildHeader(_ThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.headerStart, colors.headerEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Avatar + Name
          Row(
            children: [
              // Avatar Border Gradient
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_userEmail.isNotEmpty && _userEmail != "N/A") ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.mail,
                              color: colors.textSecondary, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pills Row
          Row(
            children: [
              if (_userDept.isNotEmpty && _userDept != "N/A")
                Flexible(
                  child: _buildHeaderPill(
                    text: _userDept,
                    icon: Icons.business_center,
                    // In Light mode, we darken the tint slightly for contrast
                    baseColor: const Color(0xFF818CF8),
                    colors: colors,
                  ),
                ),
              if (_userDept.isNotEmpty && _userDept != "N/A")
                const SizedBox(width: 10),

              if (_workPhone != "Not Alloted")
                Flexible(
                  child: _buildHeaderPill(
                    text: _workPhone,
                    icon: Icons.phone_iphone,
                    baseColor: const Color(0xFF34D399),
                    colors: colors,
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required String text,
    required IconData icon,
    required Color baseColor,
    required _ThemeColors colors,
  }) {
    // Dynamic text color for pills: lighter in dark mode, darker in light mode
    final textColor = colors.isDark ? baseColor.withGreen(255) : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(colors.isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
            color: baseColor.withOpacity(colors.isDark ? 0.3 : 0.2),
            width: 1.5
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: baseColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor, // Specific text color
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION ITEM
  // ---------------------------------------------------------------------------
  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    required _ThemeColors colors,
    bool isDestructive = false,
  }) {
    // Destructive (Red) items get special styling
    final backgroundColor = isDestructive
        ? tint.withOpacity(0.1)
        : colors.itemBg; // Standard pill bg

    final borderColor = isDestructive
        ? tint.withOpacity(0.2)
        : colors.itemBorder;

    final textColor = isDestructive ? tint : colors.textPrimary;
    final iconColor = isDestructive ? tint : tint; // Keep brand tint for normal icons too

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: colors.textSecondary.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE ITEM
  // ---------------------------------------------------------------------------
  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required Color tint,
    required bool value,
    required ValueChanged<bool> onChanged,
    required _ThemeColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.itemBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: colors.itemBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: tint, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: tint,
              inactiveTrackColor: colors.textSecondary.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VERSION ITEM
  // ---------------------------------------------------------------------------
  Widget _buildVersionItem(String version, _ThemeColors colors) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: colors.versionPillBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: colors.itemBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "v$version",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// THEME CONFIGURATION
// -----------------------------------------------------------------------------

abstract class _ThemeColors {
  bool get isDark;
  Color get drawerBg;
  Color get headerStart;
  Color get headerEnd;
  Color get avatarBg;
  Color get textPrimary;
  Color get textSecondary;
  Color get divider;
  Color get itemBg;
  Color get itemBorder;
  Color get versionPillBg;
}

class _DarkColors implements _ThemeColors {
  @override bool get isDark => true;
  @override Color get drawerBg => const Color(0xFF0B1220);
  @override Color get headerStart => const Color(0xFF1E293B);
  @override Color get headerEnd => const Color(0xFF0F172A);
  @override Color get avatarBg => const Color(0xFF212A38);
  @override Color get textPrimary => Colors.white;
  @override Color get textSecondary => const Color(0xFF94A3B8); // Slate 400
  @override Color get divider => Colors.white.withOpacity(0.04);
  @override Color get itemBg => Colors.transparent;
  @override Color get itemBorder => Colors.white.withOpacity(0.08);
  @override Color get versionPillBg => Colors.black.withOpacity(0.2);
}

class _LightColors implements _ThemeColors {
  @override bool get isDark => false;
  @override Color get drawerBg => const Color(0xFFF8FAFC); // Slate 50
  @override Color get headerStart => Colors.white;
  @override Color get headerEnd => const Color(0xFFF1F5F9); // Slate 100
  @override Color get avatarBg => const Color(0xFFE2E8F0); // Slate 200
  @override Color get textPrimary => const Color(0xFF0F172A); // Slate 900
  @override Color get textSecondary => const Color(0xFF64748B); // Slate 500
  @override Color get divider => Colors.black.withOpacity(0.05);
  @override Color get itemBg => Colors.white;
  @override Color get itemBorder => const Color(0xFFE2E8F0); // Slate 200
  @override Color get versionPillBg => Colors.black.withOpacity(0.03);
}