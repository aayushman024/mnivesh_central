import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../Providers/location_provider.dart';
import '../../../ViewModels/attendance_viewModel.dart';
import 'LocationRow.dart';
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
          _PunchButton(isCheckedIn: isCheckedIn),
          SizedBox(height: 20.sdp),
          // Location row — has its own provider.select, never triggers above
          const LocationRow(),
        ],
      ),
    );
  }
}


// ── Punch button ──────────────────────────────────────────────────────────────

class _PunchButton extends ConsumerWidget {
  final bool isCheckedIn;
  const _PunchButton({required this.isCheckedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locationReady = ref.watch(
      locationProvider.select((s) => s.status == LocationStatus.ready),
    );

    return SizedBox(
      width: double.infinity,
      height: 54.sdp,
      child: ElevatedButton(
        onPressed: locationReady
            ? () => ref.read(attendanceProvider.notifier).togglePunch()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyle.extraBold.normal().copyWith(inherit: false),
          disabledBackgroundColor: theme.primaryColor.withOpacity(0.38),
          disabledForegroundColor: Colors.white.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.sdp),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.handTap(), size: 24.sdp),
            SizedBox(width: 8.sdp),
            Text(
              isCheckedIn ? 'Check Out' : 'Check In',
              style: AppTextStyle.bold
                  .normal(Colors.white)
                  .copyWith(inherit: false),
            ),
          ],
        ),
      ),
    );
  }
}