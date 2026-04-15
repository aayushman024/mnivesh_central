import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/attendance_viewModel.dart';

class PunchInStat extends ConsumerWidget {
  const PunchInStat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(attendanceProvider.select((s) => s.firstPunchInTime));
    return _StatTile(
      label: 'Check In',
      time: time != null ? DateFormat('hh:mm a').format(time) : '--:--',
      icon: PhosphorIcons.arrowDownLeft(),
      iconColor: Colors.green,
    );
  }
}

// ── Punch-out stat ────────────────────────────────────────────────────────────

class PunchOutStat extends ConsumerWidget {
  const PunchOutStat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(attendanceProvider.select((s) => s.punchOutTime));
    return _StatTile(
      label: 'Check Out',
      time: time != null ? DateFormat('hh:mm a').format(time) : '--:--',
      icon: PhosphorIcons.arrowUpRight(),
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