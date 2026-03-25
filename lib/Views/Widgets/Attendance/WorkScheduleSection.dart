// features/attendance/view/widgets/work_schedule_section.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../Models/attendance_shiftLog.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

class WorkScheduleSection extends StatelessWidget {
  final List<ShiftLog> logs;
  final VoidCallback? onViewMore;

  const WorkScheduleSection({
    super.key,
    required this.logs,
    this.onViewMore,
  });

  // ── Static helpers ────────────────────────────────────────────────────────

  static String _monthAbbr(int m) => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m - 1];

  String _weekRange() {
    if (logs.isEmpty) return '';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${_monthAbbr(d.month)}-${d.year}';
    return '${fmt(logs.first.date)} to ${fmt(logs.last.date)}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final onSurf  = theme.colorScheme.onSurface;
    final today   = DateTime.now();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.sdp, 20.sdp, 20.sdp, 0),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(20.sdp),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44.sdp,
                height: 44.sdp,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12.sdp),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.calendarBlank(),
                    color: const Color(0xFF7C3AED),
                    size: 22.sdp,
                  ),
                ),
              ),
              SizedBox(width: 12.sdp),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Work Schedule',
                      style: AppTextStyle.bold.normal(onSurf)),
                  SizedBox(height: 2.sdp),
                  Text(
                    _weekRange(),
                    style: AppTextStyle.normal.small(onSurf.withOpacity(0.5)),
                  ),
                ],
              ),
            ],
          ),


          // ── Shift rows ─────────────────────────────────────────────────
          ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.sdp, vertical: 10.sdp),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (_, i) {
          final log = logs[i];
          final isToday = log.date.year == today.year &&
          log.date.month == today.month &&
          log.date.day == today.day;

          return Column(
          children: [
          _ShiftRow(
          log: log,
          isDark: isDark,
          isToday: isToday,
          ),

          // Divider (avoid showing after last item)
          if (i != logs.length - 1)
          Divider(
          height: 1,
          thickness: 1,
          color: isDark
          ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          ),
          ],
          );
          },
          ),

          SizedBox(height: 12.sdp),

          // ── View More button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46.sdp,
            child: OutlinedButton.icon(
              onPressed: onViewMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.sdp),
                ),
              ),
              icon: Icon(PhosphorIcons.arrowRight(), size: 18.sdp),
              label: Text(
                'View More',
                style: AppTextStyle.bold.normal(theme.colorScheme.onSurface)
                    .copyWith(inherit: false),
              ),
            ),
          ),
          SizedBox(height: 20.sdp),
        ],
      ),
    );
  }
}


// ── Single shift row — pure StatelessWidget ───────────────────────────────────

class _ShiftRow extends StatelessWidget {
  final ShiftLog log;
  final bool isDark;
  final bool isToday;

  const _ShiftRow({
    required this.log,
    required this.isDark,
    required this.isToday,
  });

  static const _dayAbbrs = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static ({String label, Color color}) _statusMeta(ShiftStatus s) =>
      switch (s) {
        ShiftStatus.weekend           => (label: 'Weekend', color: Color(0xFF4B5563)),
        ShiftStatus.working           => (label: 'Working', color: Color(0xFF16A34A)),
        ShiftStatus.casualLeave       => (label: 'Casual Leave', color: Color(0xFF0F766E)),
        ShiftStatus.absent            => (label: 'Absent', color: Color(0xFFB91C1C)),
        ShiftStatus.emergencyLeave    => (label: 'Emergency Leave', color: Color(0xFFB91C1C)),
        ShiftStatus.shortLeave        => (label: 'Short Leave', color: Color(0xFFFF8100)),
        ShiftStatus.birthdayLeave     => (label: 'Birthday Leave', color: Color(0xFF0EA5A4)),
        ShiftStatus.compOff           => (label: 'Compensatory Off', color: Color(0xFFB45309)),
        ShiftStatus.dayLeave          => (label: 'Day Leave', color: Color(0xFF777F04)),
        ShiftStatus.earnedLeave       => (label: 'Earned Leave', color: Color(0xFF166534)),
        ShiftStatus.flexibleSaturday  => (label: 'Flexible Saturday', color: Color(0xFFD97706)),
        ShiftStatus.meeting           => (label: 'Meeting with Client', color: Color(0xFF0E7490)),
        ShiftStatus.restrictedHoliday => (label: 'Restricted Holiday', color: Color(0xFFB91C1C)),
        ShiftStatus.wfh               => (label: 'Work from Home', color: Color(0xFFA3A300)),
        ShiftStatus.wfhOnRequest      => (label: 'Work from Home on Request', color: Color(0xFFCA8A04)),
      };

  static String _fmtHours(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
          '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final onSurf = theme.colorScheme.onSurface;
    final meta   = _statusMeta(log.status);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.sdp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Date & day ────────────────────────────────────────────────
          SizedBox(
            width: 36.sdp,
            child: Column(
              children: [
                Text(
                  log.date.day.toString(),
                  style: AppTextStyle.extraBold.normal(onSurf)
                      .copyWith(fontSize: 20.sdp),
                ),
                Text(
                  _dayAbbrs[log.date.weekday - 1],
                  style: AppTextStyle.normal
                      .small(onSurf.withOpacity(0.45)),
                ),
              ],
            ),
          ),

          SizedBox(width: 14.sdp),

          // ── Shift info ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.briefcase(),
                        size: 13.sdp, color: onSurf.withOpacity(0.45)),
                    SizedBox(width: 4.sdp),
                    Text(
                      log.shiftName,
                      style: AppTextStyle.bold.normal(onSurf)
                          .copyWith(fontSize: 14.sdp),
                    ),
                  ],
                ),
                SizedBox(height: 3.sdp),
                Row(
                  children: [
                    Icon(PhosphorIcons.clock(),
                        size: 13.sdp, color: onSurf.withOpacity(0.35)),
                    SizedBox(width: 4.sdp),
                    Text(
                      log.shiftTiming,
                      style: AppTextStyle.normal
                          .small(onSurf.withOpacity(0.5)),
                    ),
                  ],
                ),
                SizedBox(height: 6.sdp),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.sdp, vertical: 2.sdp),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.sdp),
                  ),
                  child: Text(
                    meta.label,
                    style: AppTextStyle.bold.small(meta.color),
                  ),
                ),
              ],
            ),
          ),

          // ── Hours — hidden for today and future ───────────────────────
         if (!isToday && log.totalHours != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtHours(log.totalHours!),
                  style: AppTextStyle.extraBold.normal(onSurf)
                      .copyWith(fontSize: 16.sdp),
                ),
                Text(
                  'Hrs',
                  style: AppTextStyle.normal
                      .small(onSurf.withOpacity(0.45)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}