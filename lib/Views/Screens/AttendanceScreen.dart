import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';

import '../../../Utils/Dimensions.dart';
import '../../Providers/location_provider.dart';
import '../../ViewModels/announcement_viewModel.dart';
import '../../ViewModels/attendance_viewModel.dart';
import '../Widgets/Attendance/PunchCard.dart';
import '../Widgets/Attendance/WorkScheduleSection.dart';
import '../Widgets/homeAppBar.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({
    super.key,
  });

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
      // AuthManager.decodeAndPrintAccessToken();
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
        ref
            .read(announcementViewModelProvider.notifier)
            .fetchAnnouncements(forceRefresh: true),
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
        ),
        // Positioned.fill(
        //   child: ClipRect(
        //     child: BackdropFilter(
        //       filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        //       child: Container(
        //         color: Theme.of(context).brightness == Brightness.dark
        //             ? Colors.black.withOpacity(0.4)
        //             : Colors.white.withOpacity(0.4),
        //         alignment: Alignment.center,
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.end,
        //           spacing: 15.sdp,
        //           children: [
        //             Lottie.asset('assets/Maintenance.json',
        //             height: 200.sdp),
        //             Text("COMING SOON",
        //             style: AppTextStyle.bold.large().copyWith(letterSpacing: 10)),
        //             SizedBox(height: 50.sdp),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
