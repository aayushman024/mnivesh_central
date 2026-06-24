import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/core/providers/profile_image_provider.dart';
import 'package:mnivesh_central/features/announcements/screens/announcement_modal_screen.dart';
import 'package:mnivesh_central/features/daftar/widgets/location_row.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/announcements/view_models/announcement_view_model.dart';
import 'package:mnivesh_central/features/auth/demo/demo_mode_provider.dart';

class HomeSliverAppBar extends ConsumerStatefulWidget {
  const HomeSliverAppBar({
    super.key,
  });

  @override
  ConsumerState<HomeSliverAppBar> createState() => _HomeSliverAppBarState();
}

class _HomeSliverAppBarState extends ConsumerState<HomeSliverAppBar> {
  String _userName = "User!";

  // Consts for consistent spacing
  static const double _expandedHeight = 140.0;
  static const double _collapsedHeight = kToolbarHeight + 15;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // In demo mode, skip SharedPreferences and show guest name
    if (ref.read(demoModeProvider)) {
      if (mounted) setState(() => _userName = 'Guest');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('UserName') ?? "User!");
    }
  }

  static String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return "Good Morning, ☀️";
    if (hour >= 12 && hour < 16) return "Good Afternoon, 🌤️";
    return "Good Evening, 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final announcements = ref.watch(announcementViewModelProvider).items;


    return SliverAppBar(
      expandedHeight: _expandedHeight,
      collapsedHeight: _collapsedHeight,
      pinned: true,
      centerTitle: false,
      automaticallyImplyLeading: true,
      // Handle leading manually for custom placement
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,

      // Fixed Menu Button
      leading: Consumer(
        builder: (context, ref, child) {
          final profileImagePath = ref.watch(profileImageProvider);
          if (profileImagePath != null && File(profileImagePath).existsSync()) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                margin: EdgeInsets.only(top: 18.sdp, left: 18.sdp),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 2.sdp,
                  ),
                  image: DecorationImage(
                    image: FileImage(File(profileImagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }
          return Container(
            margin: EdgeInsets.only(top: 18.sdp, left: 18.sdp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.sdp),
              color: theme.brightness == Brightness.dark
                  ? Colors.white10 : Colors.grey.shade300,
            ),
            child: IconButton(
              icon: Icon(
                PhosphorIconsFill.userCircle,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          );
        },
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentHeight = constraints.biggest.height;

          // Fixed progress calculation to map scroll height accurately
          final double scrollRange = _expandedHeight - _collapsedHeight;
          final double t =
              ((currentHeight - _collapsedHeight - topPadding) / scrollRange)
                  .clamp(0.0, 1.0);

          // Curve the horizontal movement so text dodges the leading icon earlier
          final double curvedT = Curves.easeOut.transform(t);
          final double leftOffset = Tween<double>(
            begin: 72.0,
            end: 20.0,
          ).transform(curvedT);

          // Position elements independently to prevent layout snaps when greeting hides
          final double nameTop = Tween<double>(
            begin: topPadding + 16.0,
            // Centered vertically in collapsed toolbar
            end: currentHeight - 35.0,
          ).transform(t);

          final double greetingTop = Tween<double>(
            begin: topPadding + 0.0, // Pushes up and out of the way
            end: currentHeight - 55.0,
          ).transform(t);

          final double fontSizeScale = Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).transform(t);

          // Fade out smoothly in the first 50% of the collapse
          final double greetingOpacity = (t * 2 - 1.0).clamp(0.0, 1.0);

          return Stack(
            children: [
              // LocationRow beside menu button
              Positioned(
                top: topPadding + 18.sdp,
                left: 72.0,
                child: Opacity(
                  opacity: greetingOpacity,
                  child: const LocationRow(),
                ),
              ),
              // Greeting
              Positioned(
                top: greetingTop,
                left: leftOffset,
                child: Opacity(
                  opacity: greetingOpacity,
                  child: Text(
                    _computeGreeting(),
                    style: AppTextStyle.normal.small(
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              // Username
              Positioned(
                top: nameTop,
                left: leftOffset,
                child: Transform.scale(
                  scale: fontSizeScale,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _userName,
                    style: AppTextStyle.extraBold.large(
                      theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Demo Mode pill — only visible when in demo mode
        Consumer(
          builder: (context, ref, _) {
            final isDemo = ref.watch(demoModeProvider);
            if (!isDemo) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 18.sdp, right: 5.sdp),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.sdp,
                  vertical: 4.sdp,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50.sdp),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 13,
                    ),
                    SizedBox(width: 4.sdp),
                    Text(
                      'Demo',
                      style: AppTextStyle.bold
                          .custom(11.ssp, const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(top: 18.sdp, right: 18.sdp),
          child: Badge(
            isLabelVisible: announcements.isNotEmpty,
            label: Text(
              '${announcements.length}',
              style: AppTextStyle.normal.custom(11.ssp),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.sdp),
                color: theme.brightness == Brightness.dark
                    ? Colors.white10 : Colors.grey.shade300,
              ),
              child: IconButton(
                tooltip: "Notifications",
                onPressed: () {
                  AnnouncementModal.show(
                    context,
                    initialItems: announcements,
                  );
                },
                icon: Icon(
                  PhosphorIconsFill.bellSimple
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
