import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mnivesh_central/core/api/api_config.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/features/auth/managers/auth_wrapper.dart';
import 'package:mnivesh_central/features/app_store/providers/app_provider.dart';
import 'package:mnivesh_central/core/providers/profile_image_provider.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/core/services/cache_service.dart';
import 'package:mnivesh_central/features/team_status/screens/team_status_screen.dart';

class HomeDrawer extends ConsumerStatefulWidget {
  const HomeDrawer({super.key});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _userName = "User";
  String _userEmail = "Loading...";
  String _userDept = "Loading...";
  String _workPhone = "Loading...";
  String _cacheSize = "Calculating...";
  bool _isLoggingOut = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadCacheSize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('UserName') ?? "User";
      _userEmail = prefs.getString('UserEmail') ?? "No email provided";
      _userDept = prefs.getString('user_department') ?? "N/A";
      _workPhone = prefs.getString('workPhone') ?? "Not Allotted";
    });
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheService.getCacheSize();
    if (!mounted) return;
    setState(() {
      _cacheSize = CacheService.formatBytes(size);
    });
  }

  Future<void> _clearCache() async {
    if (_isClearingCache) return;
    setState(() => _isClearingCache = true);
    
    await CacheService.clearCache();
    await _loadCacheSize(); // Refresh size
    
    if (!mounted) return;
    setState(() => _isClearingCache = false);
  }

  String get _initials {
    if (_userName.isEmpty) return "U";
    final parts = _userName.trim().split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : parts[0][0].toUpperCase();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    await AuthManager.logout();
    await ref.read(profileImageProvider.notifier).clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final colors = isDark ? _DarkColors() : _LightColors();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: colors.drawerBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32.sdp),
          bottomRight: Radius.circular(32.sdp),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(colors),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: 16.sdp),

                SizedBox(height: 16.sdp),
                
                // --- App Settings Accordion ---
                _buildSettingsAccordion(colors, isDark),

                // // --- Management Section ---
                if (_userDept == "IT Desk" || _userDept == "Management") ...[
                  _buildActionItem(
                    label: "Team Status",
                    icon: PhosphorIconsRegular.usersThree,
                    tint: const Color(0xFFFFB266),
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeamStatusScreen(),
                        ),
                      );
                    },
                  ),
                ],

                // _buildActionItem(
                //   label: "Announcements",
                //   icon: PhosphorIconsRegular.megaphone,
                //   tint: const Color(0xFF78CC2A),
                //   colors: colors,
                //   onTap: () {
                //     Navigator.pop(context);
                //     SnackbarService.showComingSoon();
                //   },
                // ),

                // --- Divider ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.sdp,
                    horizontal: 32.sdp,
                  ),
                  child: Divider(color: colors.divider, thickness: 1),
                ),

                // --- Logout ---
                _buildActionItem(
                  label: "Logout",
                  icon: PhosphorIconsRegular.signOut,
                  tint: const Color(0xFFF44336),
                  isDestructive: true,
                  colors: colors,
                  onTap: _logout,
                ),

                SizedBox(height: 24.sdp),
                _buildVersionItem(ApiConfig.appVersion, colors),
                SizedBox(height: 24.sdp),
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
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final profileImagePath = ref.watch(profileImageProvider);
                  if (profileImagePath != null && File(profileImagePath).existsSync()) {
                    return Container(
                      width: 72.sdp,
                      height: 72.sdp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          width: 2.sdp,
                        ),
                        image: DecorationImage(
                          image: FileImage(File(profileImagePath)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 72.sdp,
                    height: 72.sdp,
                    padding: EdgeInsets.all(4.sdp),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.avatarBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: AppTextStyle.extraBold.custom(
                          26.ssp,
                          colors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16.sdp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: AppTextStyle.extraBold.custom(19.ssp, colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_userEmail.isNotEmpty && _userEmail != "N/A") ...[
                      SizedBox(height: 4.sdp),
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.envelope,
                            color: colors.textSecondary,
                            size: 14,
                          ),
                          SizedBox(width: 6.sdp),
                          Expanded(
                            child: Text(
                              _userEmail,
                              style: AppTextStyle.normal.custom(
                                12.ssp,
                                colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.sdp),
          Row(
            children: [
              if (_userDept.isNotEmpty && _userDept != "N/A")
                Flexible(
                  child: _buildHeaderPill(
                    text: _userDept,
                    icon: PhosphorIconsRegular.briefcase,
                    lightColor: const Color(0xFF1E40AF),
                    darkColor: const Color(0xFF60A5FA),
                    colors: colors,
                  ),
                ),
              if (_userDept.isNotEmpty && _userDept != "N/A")
                SizedBox(width: 10.sdp),

              if (_workPhone != "Not Alloted")
                Flexible(
                  child: _buildHeaderPill(
                    text: _workPhone,
                    icon: PhosphorIconsRegular.deviceMobileCamera,
                    lightColor: const Color(0xFF475569),
                    darkColor: const Color(0xFF94A3B8),
                    colors: colors,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required String text,
    required IconData icon,
    required Color lightColor,
    required Color darkColor,
    required _ThemeColors colors,
  }) {
    final activeColor = colors.isDark ? darkColor : lightColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 4.sdp),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50.sdp),
        border: Border.all(color: activeColor.withOpacity(0.2), width: 1.5.sdp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: activeColor, size: 16),
          SizedBox(width: 6.sdp),
          Flexible(
            child: Text(
              text,
              style: AppTextStyle.bold.custom(
                11.ssp,
                activeColor,
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
    Widget? trailing,
    double? horizontalPadding,
  }) {
    final backgroundColor = isDestructive
        ? tint.withOpacity(0.1)
        : colors.itemBg;

    final borderColor = isDestructive
        ? tint.withOpacity(0.2)
        : colors.itemBorder;

    final textColor = isDestructive ? tint : colors.textPrimary;
    final iconColor = tint;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 16.sdp, 
        vertical: 8.sdp,
      ),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.sdp),
          side: BorderSide(color: borderColor, width: 1.sdp),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50.sdp),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18.sdp, horizontal: 16.sdp),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                SizedBox(width: 16.sdp),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyle.normal.custom(
                      14.ssp,
                      textColor,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  SizedBox(width: 8.sdp),
                ],
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required Color tint,
    required bool value,
    required ValueChanged<bool> onChanged,
    required _ThemeColors colors,
    double? horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 16.sdp, 
        vertical: 6.sdp,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.itemBg,
          borderRadius: BorderRadius.circular(50.sdp),
          border: Border.all(color: colors.itemBorder, width: 1.sdp),
        ),
        padding: EdgeInsets.symmetric(vertical: 4.sdp, horizontal: 16.sdp),
        child: Row(
          children: [
            Icon(icon, color: tint, size: 22),
            SizedBox(width: 16.sdp),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.normal.custom(
                  14.ssp,
                  colors.textPrimary,
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
  // SETTINGS ACCORDION
  // ---------------------------------------------------------------------------
  Widget _buildSettingsAccordion(_ThemeColors colors, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 4.sdp),
      child: Container(
        decoration: BoxDecoration(
          color: colors.itemBg,
          borderRadius: BorderRadius.circular(24.sdp),
          border: Border.all(color: colors.itemBorder, width: 1.sdp),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            // key: const PageStorageKey('app_settings_expansion'),
            leading: Icon(
              PhosphorIconsRegular.gearSix,
              color: const Color(0xFF6366F1), // Indigo
              size: 22,
            ),
            title: Text(
              "App Settings",
              style: AppTextStyle.normal.custom(
                14.ssp,
              ),
            ),
            iconColor: colors.textSecondary,
            collapsedIconColor: colors.textSecondary,
            childrenPadding: EdgeInsets.only(bottom: 12.sdp),
            children: [
              // Theme Toggle
              _buildToggleItem(
                label: "Dark Mode",
                icon: isDark ? PhosphorIconsRegular.moonStars : PhosphorIconsRegular.sun,
                tint: const Color(0xFF38BDF8),
                value: isDark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                colors: colors,
                horizontalPadding: 12.sdp,
              ),
              
              // Clear Cache Button
              _buildActionItem(
                label: "Clear Cache",
                icon: PhosphorIconsRegular.trash,
                tint: const Color(0xFFF59E0B), // Amber
                trailing: Text(
                  _cacheSize,
                  style: AppTextStyle.normal.custom(
                    11.ssp,
                    colors.textSecondary,
                  ),
                ),
                colors: colors,
                horizontalPadding: 12.sdp,
                onTap: _clearCache,
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(50.sdp),
          border: Border.all(color: colors.itemBorder, width: 1.sdp),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 6.sdp),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "v$version",
              style: AppTextStyle.normal.custom(
                11.ssp,
                colors.textSecondary,
              ),
            ),
            SizedBox(width: 6.sdp),
            Container(
              width: 5.sdp,
              height: 5.sdp,
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            ),
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
  @override
  bool get isDark => true;
  @override
  Color get drawerBg => const Color(0xFF0B1220);
  @override
  Color get headerStart => const Color(0xFF1E293B);
  @override
  Color get headerEnd => const Color(0xFF0F172A);
  @override
  Color get avatarBg => const Color(0xFF212A38);
  @override
  Color get textPrimary => Colors.white;
  @override
  Color get textSecondary => const Color(0xFF94A3B8);
  @override
  Color get divider => Colors.white.withOpacity(0.04);
  @override
  Color get itemBg => Colors.transparent;
  @override
  Color get itemBorder => Colors.white.withOpacity(0.08);
  @override
  Color get versionPillBg => Colors.black.withOpacity(0.2);
}

class _LightColors implements _ThemeColors {
  @override
  bool get isDark => false;
  @override
  Color get drawerBg => const Color(0xFFF8FAFC);
  @override
  Color get headerStart => Colors.white;
  @override
  Color get headerEnd => const Color(0xFFF1F5F9);
  @override
  Color get avatarBg => const Color(0xFFE2E8F0);
  @override
  Color get textPrimary => const Color(0xFF0F172A);
  @override
  Color get textSecondary => const Color(0xFF64748B);
  @override
  Color get divider => Colors.black.withOpacity(0.05);
  @override
  Color get itemBg => Colors.white;
  @override
  Color get itemBorder => const Color(0xFFE2E8F0);
  @override
  Color get versionPillBg => Colors.black.withOpacity(0.03);
}
