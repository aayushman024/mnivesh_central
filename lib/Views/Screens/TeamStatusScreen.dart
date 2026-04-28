import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mnivesh_central/Views/Widgets/ModuleAppBar.dart';

import '../../Models/appModel.dart';
import '../../Models/userDetailsModel.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/teamStatus_viewModel.dart';

class TeamStatusScreen extends ConsumerWidget {
  const TeamStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // listening to the combined state here
    final state = ref.watch(teamStatusViewModelProvider);
    final viewModel = ref.read(teamStatusViewModelProvider.notifier);

    return Scaffold(
      appBar: ModuleAppBar(title: "Team Status"),
      backgroundColor: theme.scaffoldBackgroundColor,
      // unpacking the AsyncValue manually
      body: state.data.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(strokeWidth: 3),
        ),
        error: (err, stack) => _buildErrorState(colorScheme, viewModel),
        data: (data) {
          final filteredUsers = state.filteredUsers;
          final managedApps = data.managedApps;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSearchAndSortBar(theme, colorScheme, state, viewModel),
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
    );
  }

  Widget _buildSearchAndSortBar(
    ThemeData theme,
    ColorScheme colorScheme,
    TeamStatusState state,
    TeamStatusViewModel viewModel,
  ) {
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      pinned: true,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 8.sdp),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                // piping the updates to the viewModel
                onChanged: viewModel.updateSearchQuery,
                style: AppTextStyle.normal.normal(colorScheme.onSurface),
                decoration: InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.sdp),
                  ),
                  hintText: "Search name, dept, or apps...",
                  hintStyle: AppTextStyle.light.small(
                    colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.sdp),
                ),
              ),
            ),
            SizedBox(width: 12.sdp),
            InkWell(
              onTap: viewModel.toggleSortOrder,
              borderRadius: BorderRadius.circular(16.sdp),
              child: Container(
                height: 56.sdp,
                width: 56.sdp,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16.sdp),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  state.latestFirst
                      ? Icons.filter_list_rounded
                      : Icons.filter_list_off_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
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
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.2),
            ),
            SizedBox(height: 16.sdp),
            Text(
              "No team members match your search",
              style: AppTextStyle.normal.normal(colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ColorScheme colorScheme,
    TeamStatusViewModel viewModel,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.sdp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.sdp),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: colorScheme.error,
                size: 40,
              ),
            ),
            SizedBox(height: 24.sdp),
            Text(
              "Sync Failed",
              style: AppTextStyle.extraBold.large(colorScheme.onSurface),
            ),
            SizedBox(height: 8.sdp),
            Text(
              "Unable to reach the management server.",
              textAlign: TextAlign.center,
              style: AppTextStyle.normal.normal(colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 32.sdp),
            ElevatedButton(
              onPressed: viewModel.retryConnection,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.sdp),
                ),
              ),
              child: const Text("Retry Connection"),
            ),
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
    required this.managedApps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 24.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28.sdp),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.sdp),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.sdp),
              child: Column(
                children: [
                  Row(
                    spacing: 5.sdp,
                    children: [
                      _buildAvatar(colorScheme),
                      SizedBox(width: 16.sdp),
                      Expanded(
                        child: Column(
                          spacing: 8.sdp,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.bold.normal(
                                colorScheme.onSurface,
                              ),
                            ),
                            // Text(
                            //   user.email,
                            //   style: AppTextStyle.light.small(
                            //     colorScheme.onSurfaceVariant,
                            //   ),
                            // ),
                            _buildDeptChip(colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.sdp),
                  Row(
                    children: [
                      _buildStatusPill(
                        Icons.smartphone_rounded,
                        user.deviceModel,
                        colorScheme.primary,
                        colorScheme,
                      ),
                      SizedBox(width: 12.sdp),
                      _buildStatusPill(
                        Icons.history_rounded,
                        _formatDate(user.lastSeen),
                        colorScheme.tertiary,
                        colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.sdp),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.02),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.05),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOSVersionPill(user.osVersion, colorScheme, isDark),
                  SizedBox(height: 24.sdp),
                  Row(
                    children: [
                      Text(
                        "APPS INSTALLED",
                        style: AppTextStyle.extraBold
                            .small(colorScheme.onSurfaceVariant)
                            .copyWith(letterSpacing: 2.0),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.sdp,
                          vertical: 2.sdp,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.sdp),
                        ),
                        child: Text(
                          "${user.appsInstalled.length} Total",
                          style: AppTextStyle.extraBold.small(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.sdp),
                  if (user.appsInstalled.isEmpty)
                    _buildEmptyApps(colorScheme)
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: user.appsInstalled
                          .map((app) => _buildAppChip(app, colorScheme))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _initials {
    if (user.username.isEmpty) return "U";
    final parts = user.username.trim().split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : parts[0][0].toUpperCase();
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Container(
      width: 42.sdp,
      height: 42.sdp,
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
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.ssp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeptChip(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.sdp),
      ),
      child: Text(
        user.department.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.normal.small(colorScheme.secondary),
      ),
    );
  }

  Widget _buildStatusPill(
    IconData icon,
    String label,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.sdp, horizontal: 12.sdp),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.sdp),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 10.sdp),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.normal.small(colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOSVersionPill(
    String version,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isIOS = version.contains("iOS");

    final brandColor = isIOS
        ? (isDark ? Colors.grey[300]! : Colors.grey[800]!)
        : (isDark ? Colors.greenAccent[400]! : Colors.green[700]!);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 8.sdp),
      decoration: BoxDecoration(
        color: brandColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: brandColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIOS ? Icons.apple_rounded : Icons.android_rounded,
            color: brandColor,
            size: 20,
          ),
          SizedBox(width: 8.sdp),
          Text(version, style: AppTextStyle.extraBold.small(brandColor)),
        ],
      ),
    );
  }

  Widget _buildAppChip(String appString, ColorScheme colorScheme) {
    String name = appString.split('(')[0].trim();
    String version = appString.contains('(')
        ? appString.split('(')[1].replaceAll(')', '')
        : '1.0';

    final matchedApp = managedApps.firstWhere(
      (a) => a.appName.toLowerCase().trim() == name.toLowerCase(),
      orElse: () => AppModel(
        appName: '',
        packageName: '',
        version: '',
        downloadUrl: '',
        icon: '',
        description: '',
        id: '',
        isActive: true,
        changelog: '',
        colorKey: '',
        allowedDepartments: [],
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 10.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14.sdp),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matchedApp.icon.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.sdp),
              child: Image.network(
                matchedApp.icon,
                width: 20.sdp,
                height: 20.sdp,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.layers_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Icon(
              Icons.layers_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          SizedBox(width: 10.sdp),
          Text(name, style: AppTextStyle.bold.small(colorScheme.onSurface)),
          SizedBox(width: 6.sdp),
          Text(
            version,
            style: AppTextStyle.extraBold.small(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyApps(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: colorScheme.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.error),
          SizedBox(width: 12.sdp),
          Text(
            "No internal apps detected on this device",
            style: AppTextStyle.normal.small(colorScheme.error),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just Now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM dd, hh:mm a').format(date);
  }
}
