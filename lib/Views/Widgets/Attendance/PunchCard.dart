import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../Providers/location_provider.dart';
import '../../../ViewModels/attendance_viewModel.dart';
import 'LocationRow.dart';
import 'PunchButton.dart';
import 'PunchStat.dart';
import 'TimerDisplay.dart';

/// Rebuilds only when [isCheckedIn] flips. Timer and stats are isolated inside.
class PunchCard extends ConsumerWidget {
  const PunchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCheckedIn =
    ref.watch(attendanceProvider.select((s) => s.isCheckedIn));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // final nowAsync = ref.watch(clockProvider);
    //
    // final today = nowAsync.when(
    //   data: (now) => DateFormat('dd MMM yyyy, hh:mm a').format(now),
    //   loading: () => '',
    //   error: (_, __) => '',
    // );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.sdp),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24.sdp),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date label
          // Text(
          //   today,
          //   style: AppTextStyle.normal
          //       .normal(theme.colorScheme.onSurface.withOpacity(0.6)),
          // ),
          SizedBox(height: 8.sdp),

          // Timer — only widget that rebuilds every second
          const TimerDisplayRow(),

          SizedBox(height: 32.sdp),

          // Punch stats — each has its own tight provider.select
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [PunchInStat(), PunchOutStat()],
          ),
          SizedBox(height: 32.sdp),
          // CTA — rebuilds when isCheckedIn flips or location status changes
          PunchButton(isCheckedIn: isCheckedIn),
          SizedBox(height: 20.sdp),
          // Location row — has its own provider.select, never triggers above
          const LocationRow(),
        ],
      ),
    );
  }
}