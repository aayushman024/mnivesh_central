import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/appModel.dart';
import '../../Models/userDetailsModel.dart';
import '../../Services/api_service.dart';

class TeamStatusData {
  final List<UserDetail> users;
  final List<AppModel> managedApps;
  TeamStatusData(this.users, this.managedApps);
}

class TeamStatusScreen extends StatefulWidget {
  const TeamStatusScreen({super.key});

  @override
  State<TeamStatusScreen> createState() => _TeamStatusScreenState();
}

class _TeamStatusScreenState extends State<TeamStatusScreen> {
  late Future<TeamStatusData> _statusDataFuture;
  String searchQuery = "";
  bool latestFirst = true;

  @override
  void initState() {
    super.initState();
    _statusDataFuture = _initData();
  }

  Future<TeamStatusData> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('AuthToken') ?? '';

    // Fetch both in parallel
    final results = await Future.wait([
      ApiService.getUserDetails(token),
      ApiService().fetchApps(token),
    ]);

    return TeamStatusData(
      results[0] as List<UserDetail>,
      results[1] as List<AppModel>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<TeamStatusData>(
          future: _statusDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3));
            }
            if (snapshot.hasError) {
              return _buildErrorState(colorScheme);
            }

            final data = snapshot.data!;
            final users = data.users;
            final managedApps = data.managedApps;

            var filteredUsers = users.where((u) {
              final query = searchQuery.toLowerCase();
              return u.username.toLowerCase().contains(query) ||
                  u.department.toLowerCase().contains(query) ||
                  u.appsInstalled.any((a) => a.toLowerCase().contains(query));
            }).toList();

            filteredUsers.sort((a, b) => latestFirst
                ? b.lastSeen.compareTo(a.lastSeen)
                : a.lastSeen.compareTo(b.lastSeen));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(colorScheme),
                _buildSearchAndSortBar(theme, colorScheme),
                if (filteredUsers.isEmpty)
                  _buildEmptyState(colorScheme)
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => UserDetailCard(
                          user: filteredUsers[index],
                          managedApps: managedApps,
                        ),
                        childCount: filteredUsers.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                    ),
                    child: Icon(Icons.chevron_left_rounded, color: colorScheme.onSurface, size: 28),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_rounded, color: colorScheme.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Team Status",
              style: GoogleFonts.poppins(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      pinned: true,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  style: GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Search name, dept, or apps...",
                    hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => setState(() => latestFirst = !latestFirst),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Icon(
                  latestFirst ? Icons.filter_list_rounded : Icons.filter_list_off_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text("No team members match your search",
                style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colorScheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, color: colorScheme.error, size: 40),
            ),
            const SizedBox(height: 24),
            Text("Sync Failed", style: GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Unable to reach the management server.", textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (){
                setState(() {
                  _statusDataFuture = _initData();
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Retry Connection"),
            )
          ],
        ),
      ),
    );
  }
}

class UserDetailCard extends StatelessWidget {
  final UserDetail user;
  final List<AppModel> managedApps;

  const UserDetailCard({
    super.key,
    required this.user,
    required this.managedApps
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(colorScheme),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username,
                                style: GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(user.email,
                                style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildDeptChip(colorScheme),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatusPill(Icons.smartphone_rounded, user.deviceModel, colorScheme.primary, colorScheme),
                      const SizedBox(width: 12),
                      _buildStatusPill(Icons.history_rounded, _formatDate(user.lastSeen), colorScheme.tertiary, colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            // --- Enlarged Details Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24), // Increased padding
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.02),
                border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOSVersionPill(user.osVersion, colorScheme, isDark),
                  const SizedBox(height: 24), // Increased gap
                  Row(
                    children: [
                      Text("APPS INSTALLED",
                          style: GoogleFonts.poppins(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12, // Increased font size
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0 // Increased spacing
                          )),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("${user.appsInstalled.length} Total",
                            style: GoogleFonts.poppins(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Increased gap
                  if (user.appsInstalled.isEmpty)
                    _buildEmptyApps(colorScheme)
                  else
                    Wrap(
                      spacing: 10, // Increased spacing
                      runSpacing: 10,
                      children: user.appsInstalled.map((app) => _buildAppChip(app, colorScheme)).toList(),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.username[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeptChip(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        user.department.toUpperCase(),
        style: GoogleFonts.poppins(color: colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatusPill(IconData icon, String label, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
        const SizedBox(width: 12),
        Text("$label:", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Updated pill design for OS Version
  Widget _buildOSVersionPill(String version, ColorScheme colorScheme, bool isDark) {
    // Use a slightly brighter green for dark mode readability
    final brandGreen = isDark ? Colors.greenAccent[400]! : Colors.green[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: brandGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.android_rounded, color: brandGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            version,
            style: GoogleFonts.poppins(
              color: brandGreen,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Larger App Chip ---
  Widget _buildAppChip(String appString, ColorScheme colorScheme) {
    String name = appString.split('(')[0].trim();
    String version = appString.contains('(') ? appString.split('(')[1].replaceAll(')', '') : '1.0';

    final matchedApp = managedApps.firstWhere(
          (a) => a.appName.toLowerCase().trim() == name.toLowerCase(),
      orElse: () => AppModel(appName: '', packageName: '', version: '', downloadUrl: '', icon: '', description: '', id: '', isActive: true, changelog: '', colorKey: '', ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Increased internal padding
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14), // More rounded
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)), // Slightly more visible border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matchedApp.icon.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                matchedApp.icon,
                width: 20, // Increased icon size
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.layers_rounded, size: 18, color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            Icon(Icons.layers_rounded, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10), // Increased gap
          Text(name, style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 13, // Increased font size
              fontWeight: FontWeight.w600
          )),
          const SizedBox(width: 6),
          Text(version, style: GoogleFonts.poppins(
              color: colorScheme.primary,
              fontSize: 11, // Increased font size
              fontWeight: FontWeight.bold
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyApps(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.error),
          const SizedBox(width: 12),
          Text("No internal apps detected on this device",
              style: GoogleFonts.poppins(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Live Now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM dd, hh:mm a').format(date);
  }
}