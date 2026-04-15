import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../Utils/Dimensions.dart';
import '../../Providers/location_provider.dart';
import '../../ViewModels/attendance_viewModel.dart';
import '../Widgets/Attendance/PunchCard.dart';
import '../Widgets/Attendance/WorkScheduleSection.dart';
import '../Widgets/homeAppBar.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
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
        ref.read(scheduleProvider.notifier).fetchCurrentWeek(),
      ],
      eagerError: true,
      cleanUp: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(scheduleProvider);

    return RefreshIndicator(
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
                  // SizedBox(height: 15.sdp),
                  // const LeaveCard(),
                  SizedBox(height: 15.sdp),
                  WorkScheduleSection(),
                  SizedBox(height: 34.sdp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}