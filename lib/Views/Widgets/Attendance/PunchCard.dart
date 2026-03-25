// features/attendance/view/widgets/punch_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../ViewModels/attendance_viewModel.dart';
import 'TimerDisplay.dart';

/// Rebuilds only when [isCheckedIn] flips. Timer and stats are isolated inside.
class PunchCard extends ConsumerWidget {
  const PunchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCheckedIn =
    ref.watch(attendanceProvider.select((s) => s.isCheckedIn));
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nowAsync = ref.watch(clockProvider);

    final today = nowAsync.when(
      data: (now) => DateFormat('dd MMM yyyy, hh:mm a').format(now),
      loading: () => '',
      error: (_, __) => '',
    );

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
          Text(
            today,
            style: AppTextStyle.normal
                .normal(theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          SizedBox(height: 24.sdp),

          // Timer — only widget that rebuilds every second
          const TimerDisplayRow(),

          SizedBox(height: 32.sdp),

          // Punch stats — each has its own tight provider.select
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_PunchInStat(), _PunchOutStat()],
          ),

          SizedBox(height: 32.sdp),

          // CTA — rebuilds only when isCheckedIn flips
          _PunchButton(isCheckedIn: isCheckedIn),
        ],
      ),
    );
  }
}

// ── Punch-in stat ─────────────────────────────────────────────────────────────

class _PunchInStat extends ConsumerWidget {
  const _PunchInStat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(attendanceProvider.select((s) => s.punchInTime));
    return _StatTile(
      label:     'Punch In',
      time:      time != null ? DateFormat('hh:mm a').format(time) : '--:--',
      icon:      PhosphorIcons.arrowDownLeft(),
      iconColor: Colors.green,
    );
  }
}

// ── Punch-out stat ────────────────────────────────────────────────────────────

class _PunchOutStat extends ConsumerWidget {
  const _PunchOutStat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(attendanceProvider.select((s) => s.punchOutTime));
    return _StatTile(
      label:     'Punch Out',
      time:      time != null ? DateFormat('hh:mm a').format(time) : '--:--',
      icon:      PhosphorIcons.arrowUpRight(),
      iconColor: Colors.redAccent,
    );
  }
}

// ── Shared stat tile (pure StatelessWidget) ───────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20.sdp),
            SizedBox(width: 4.sdp),
            Text(time,
                style: AppTextStyle.bold.normal(theme.colorScheme.onSurface)),
          ],
        ),
        SizedBox(height: 4.sdp),
        Text(
          label,
          style: AppTextStyle.light
              .small(theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}

// ── Punch button — stateless, isCheckedIn passed from parent ─────────────────

class _PunchButton extends ConsumerWidget {
  final bool isCheckedIn;
  const _PunchButton({required this.isCheckedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 54.sdp,
      child: ElevatedButton(
        onPressed: () =>
            ref.read(attendanceProvider.notifier).togglePunch(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
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
              style: AppTextStyle.bold.normal(Colors.white)
                  .copyWith(inherit: false),
            ),
          ],
        ),
      ),
    );
  }
}