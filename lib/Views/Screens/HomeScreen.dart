import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Views/Widgets/Home/QuickActionsSection.dart';
import '../../../Utils/Dimensions.dart';
import '../../Providers/location_provider.dart';
import '../../Providers/module_usage_provider.dart';
import '../../ViewModels/announcement_viewModel.dart';
import '../../ViewModels/attendance_viewModel.dart';
import '../Widgets/Attendance/PunchCard.dart';
import '../Widgets/homeAppBar.dart';


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
      ref.read(attendanceProvider.notifier).fetchLiveStatus();
      ref.read(locationProvider.notifier).refreshStatus();
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
    await Future.wait(
      [
        ref.read(locationProvider.notifier).checkAndFetch(),
        ref.read(attendanceProvider.notifier).fetchLiveStatus(),
        ref
            .read(announcementViewModelProvider.notifier)
            .fetchAnnouncements(forceRefresh: true),
        ref.read(recentModulesProvider.notifier).refresh(),
      ],
      eagerError: true,
      cleanUp: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
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
                      QuickActionsSection()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
