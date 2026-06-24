import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/features/home/widgets/announcements_banner.dart';
import 'package:mnivesh_central/features/home/widgets/quick_actions_section.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/features/daftar/providers/location_provider.dart';
import 'package:mnivesh_central/features/modules_analytics/providers/module_usage_provider.dart';
import 'package:mnivesh_central/features/announcements/view_models/announcement_view_model.dart';
import 'package:mnivesh_central/features/daftar/view_models/attendance_view_model.dart';
import 'package:mnivesh_central/features/daftar/widgets/punch_card.dart';
import 'package:mnivesh_central/features/home/widgets/home_app_bar.dart';
import 'package:mnivesh_central/features/auth/demo/demo_mode_provider.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDemo = ref.read(demoModeProvider);
      // Always load announcements (view model handles demo short-circuit)
      ref.read(announcementViewModelProvider.notifier).fetchAnnouncements(forceRefresh: true);
      if (!isDemo) {
        ref.read(locationProvider.notifier).refreshStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onRefresh();
    }
  }

  Future<void> _onRefresh() async {
    final isDemo = ref.read(demoModeProvider);
    if (isDemo) {
      // In demo mode just re-apply the hardcoded data, no network calls
      ref.read(announcementViewModelProvider.notifier).fetchAnnouncements(forceRefresh: true);
      return;
    }
    await Future.wait(
      [
        ref.read(locationProvider.notifier).checkAndFetch(),
        // ref.read(attendanceProvider.notifier).fetchLiveStatus(),
        ref.read(announcementViewModelProvider.notifier).fetchAnnouncements(forceRefresh: true),
        ref.read(recentModulesProvider.notifier).refresh(),
    AuthManager.decodeAndPrintAccessToken()
      ],
      eagerError: true,
      cleanUp: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          const HomeSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(20.sdp),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PunchCard(),
                  SizedBox(height: 15.sdp),
                  const AnnouncementsBanner(),
                  SizedBox(height: 15.sdp),
                  const QuickActionsSection()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
