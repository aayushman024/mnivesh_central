// features/attendance/view/attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Views/Widgets/Attendance/LeaveCard.dart';

import '../../../Utils/Dimensions.dart';
import '../../ViewModels/attendance_viewModel.dart';
import '../Widgets/Attendance/PunchCard.dart';
import '../Widgets/Attendance/WorkScheduleSection.dart';
import '../Widgets/homeAppBar.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(scheduleProvider);

    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),
        SliverPadding(
          padding: EdgeInsets.all(20.sdp),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PunchCard(),
                SizedBox(height: 24.sdp),
                WorkScheduleSection(
                  logs: logs,
                  onViewMore: () {
                    // TODO: navigate to full schedule screen
                  },
                ),
                SizedBox(height: 24.sdp),
                LeaveCard()
              ],
            ),
          ),
        ),
      ],
    );
  }
}