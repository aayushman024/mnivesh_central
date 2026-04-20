// features/attendance/view/widgets/work_schedule_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../Models/attendance_shiftLog.dart';
import '../../../ViewModels/attendance_viewModel.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

class WorkScheduleSection extends ConsumerWidget {
  final VoidCallback? onViewMore;
  static const String _defaultShiftTiming = '10:00 AM to 06:30 PM';

  const WorkScheduleSection({super.key, this.onViewMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);

    return GestureDetector(
      onTap: () => _openExpandedSheet(context),
      child: scheduleAsync.when(
        loading: () => _WorkScheduleBody(
          logs: _skeletonLogs(),
          onViewMore: onViewMore,
          isLoading: true,
        ),
        error: (e, _) => _ErrorCard(message: e.toString()),
        data: (logs) => _WorkScheduleBody(
          logs: logs,
          onViewMore: onViewMore,
          isLoading: false,
        ),
      ),
    );
  }

  void _openExpandedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => const _ExpandedScheduleSheet(),
    );
  }

  // Fake logs — same shape as real data so Skeletonizer can paint bones
  static List<ShiftLog> _skeletonLogs() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
      7,
      (i) => ShiftLog(
        date: monday.add(Duration(days: i)),
        shiftName: 'General Shift',
        shiftTiming: _defaultShiftTiming,
        status: ShiftStatus.working,
        totalHours: const Duration(hours: 8, minutes: 30),
      ),
    );
  }
}

// ── Expanded full bottom-sheet with week navigation ───────────────────────────

class _ExpandedScheduleSheet extends ConsumerStatefulWidget {
  const _ExpandedScheduleSheet();

  @override
  ConsumerState<_ExpandedScheduleSheet> createState() =>
      _ExpandedScheduleSheetState();
}

class _ExpandedScheduleSheetState
    extends ConsumerState<_ExpandedScheduleSheet> {
  // Offset in weeks from the current week (0 = current, -1 = last week, etc.)
  int _weekOffset = 0;
  int _lastWeekOffset = 0;
  bool _isNavigating = false;
  late final ScheduleNotifier _scheduleNotifier;

  @override
  void initState() {
    super.initState();
    _scheduleNotifier = ref.read(scheduleProvider.notifier);
  }

  static String _monthAbbr(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  DateTime _mondayForOffset(int offset) {
    final today = DateTime.now();
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: 7 * offset));
  }

  String _weekRangeLabel(int offset) {
    final monday = _mondayForOffset(offset);
    final saturday = monday.add(const Duration(days: 5));
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')} ${_monthAbbr(d.month)}';
    return '${fmt(monday)} – ${fmt(saturday)} ${saturday.year}';
  }

  Future<void> _navigate(int delta) async {
    if (_isNavigating) return;
    setState(() {
      _lastWeekOffset = _weekOffset;
      _isNavigating = true;
      _weekOffset += delta;
    });
    final monday = _mondayForOffset(_weekOffset);
    await _scheduleNotifier.fetchWeek(monday);
    if (mounted) setState(() => _isNavigating = false);
  }

  @override
  void dispose() {
    // Defer the reset to after the frame finishes — Riverpod forbids provider
    // mutations during the tree finalization phase (dispose is called while
    // BuildOwner.finalizeTree is still running).
    Future(() => _scheduleNotifier.fetchCurrentWeek());
    super.dispose();
  }

  Widget _slideTransition(Widget child, Animation<double> animation) {
    if (child.key is! ValueKey<int>) {
      return FadeTransition(opacity: animation, child: child);
    }
    final int childOffset = (child.key as ValueKey<int>).value;
    final bool isNew = childOffset == _weekOffset;
    final bool goingForward = _weekOffset > _lastWeekOffset;

    double dx = goingForward ? 1.0 : -1.0;
    if (!isNew) dx = -dx;

    final offset = Tween<Offset>(
      begin: Offset(dx * 0.4, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Container(
                  width: 40.sdp,
                  height: 4.sdp,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // ── Navigation header ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(8.sdp, 8.sdp, 8.sdp, 4.sdp),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isNavigating ? null : () => _navigate(-1),
                      icon: Icon(
                        PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                        size: 20.sdp,
                      ),
                      color: colorScheme.primary,
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          reverseDuration: const Duration(milliseconds: 450),
                          transitionBuilder: _slideTransition,
                          child: Text(
                            _weekRangeLabel(_weekOffset),
                            key: ValueKey<int>(_weekOffset),
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bold
                                .normal(colorScheme.onSurface)
                                .copyWith(fontSize: 14.sdp),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      // Disable forward if we're already on the current week
                      onPressed: (_isNavigating || _weekOffset >= 0)
                          ? null
                          : () => _navigate(1),
                      icon: Icon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        size: 20.sdp,
                      ),
                      color: _weekOffset >= 0
                          ? colorScheme.onSurface.withOpacity(0.25)
                          : colorScheme.primary,
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withAlpha(15),
              ),

              // ── Schedule list ──────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  reverseDuration: const Duration(milliseconds: 450),
                  transitionBuilder: _slideTransition,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_weekOffset),
                    child: scheduleAsync.when(
                      loading: () => Skeletonizer(
                        enabled: true,
                        child: _buildList(
                          WorkScheduleSection._skeletonLogs(),
                          isDark,
                          scrollController,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.wifiSlash(),
                              color: Colors.redAccent,
                              size: 32.sdp,
                            ),
                            SizedBox(height: 8.sdp),
                            Text(
                              'Failed to load schedule',
                              style: AppTextStyle.bold.normal(
                                colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.sdp),
                            TextButton(
                              onPressed: () => _navigate(0),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (logs) => GestureDetector(
                        onHorizontalDragEnd: (details) {
                          const threshold =
                              300.0; // px/s minimum flick velocity
                          final vx = details.primaryVelocity ?? 0;
                          if (vx > threshold) {
                            // Swipe right → go back in time (previous week)
                            if (!_isNavigating) _navigate(-1);
                          } else if (vx < -threshold) {
                            // Swipe left → go forward in time (next week)
                            if (!_isNavigating && _weekOffset < 0) _navigate(1);
                          }
                        },
                        child: _buildList(logs, isDark, scrollController),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<ShiftLog> logs,
    bool isDark,
    ScrollController scrollController,
  ) {
    final today = DateTime.now();
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(20.sdp, 12.sdp, 20.sdp, 32.sdp),
      itemCount: logs.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
      ),
      itemBuilder: (_, i) {
        final log = logs[i];
        final isToday =
            log.date.year == today.year &&
            log.date.month == today.month &&
            log.date.day == today.day;
        return _ShiftRow(log: log, isDark: isDark, isToday: isToday);
      },
    );
  }
}

// ── Inner body — receives resolved data ───────────────────────────────────────

class _WorkScheduleBody extends StatelessWidget {
  final List<ShiftLog> logs;
  final VoidCallback? onViewMore;
  final bool isLoading;

  const _WorkScheduleBody({
    required this.logs,
    required this.isLoading,
    this.onViewMore,
  });

  static String _monthAbbr(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _weekRange() {
    if (logs.isEmpty) return '';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${_monthAbbr(d.month)}-${d.year}';
    return '${fmt(logs.first.date)} to ${fmt(logs.last.date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurf = theme.colorScheme.onSurface;
    final today = DateTime.now();

    return Skeletonizer(
      enabled: isLoading,
      child: Container(
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
            // ── Header ──────────────────────────────────────────────────
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
                    Text(
                      'Work Schedule',
                      style: AppTextStyle.bold.normal(onSurf),
                    ),
                    SizedBox(height: 2.sdp),
                    Text(
                      _weekRange(),
                      style: AppTextStyle.normal.small(onSurf.withOpacity(0.5)),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  PhosphorIcons.arrowsOut(),
                  size: 16.sdp,
                  color: onSurf.withOpacity(0.35),
                ),
              ],
            ),

            // ── Shift rows ───────────────────────────────────────────────
            ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 4.sdp,
                vertical: 10.sdp,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                final isToday =
                    log.date.year == today.year &&
                    log.date.month == today.month &&
                    log.date.day == today.day;

                return Column(
                  children: [
                    _ShiftRow(log: log, isDark: isDark, isToday: isToday),
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

            // ── View More ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46.sdp,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onViewMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.sdp),
                  ),
                ),
                icon: Icon(
                  PhosphorIcons.calendarDots(),
                  color: theme.colorScheme.primary,
                  size: 18.sdp,
                ),
                label: Text(
                  'View More',
                  style: AppTextStyle.bold
                      .normal(theme.colorScheme.onSurface)
                      .copyWith(inherit: false),
                ),
              ),
            ),
            SizedBox(height: 40.sdp),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.sdp),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20.sdp),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.wifiSlash(),
            color: Colors.redAccent,
            size: 32.sdp,
          ),
          SizedBox(height: 8.sdp),
          Text(
            'Could not load schedule',
            style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
          ),
          SizedBox(height: 4.sdp),
          Text(
            message,
            style: AppTextStyle.normal.small(
              theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Single shift row — unchanged ──────────────────────────────────────────────

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
        ShiftStatus.halfDay => (label: 'Half Day', color: Color(0xFFF59E0B)),
        ShiftStatus.weekend => (label: 'Weekend', color: Color(0xFF4B5563)),
        ShiftStatus.working => (label: 'Working', color: Color(0xFF16A34A)),
        ShiftStatus.casualLeave => (
          label: 'Casual Leave',
          color: Color(0xFF0F766E),
        ),
        ShiftStatus.absent => (label: 'Absent', color: Color(0xFFB91C1C)),
        ShiftStatus.emergencyLeave => (
          label: 'Emergency Leave',
          color: Color(0xFFB91C1C),
        ),
        ShiftStatus.shortLeave => (
          label: 'Short Leave',
          color: Color(0xFFFF8100),
        ),
        ShiftStatus.birthdayLeave => (
          label: 'Birthday Leave',
          color: Color(0xFF0EA5A4),
        ),
        ShiftStatus.compOff => (
          label: 'Compensatory Off',
          color: Color(0xFFB45309),
        ),
        ShiftStatus.dayLeave => (label: 'Day Leave', color: Color(0xFF777F04)),
        ShiftStatus.earnedLeave => (
          label: 'Earned Leave',
          color: Color(0xFF166534),
        ),
        ShiftStatus.flexibleSaturday => (
          label: 'Flexible Saturday',
          color: Color(0xFFD97706),
        ),
        ShiftStatus.meeting => (
          label: 'Meeting with Client',
          color: Color(0xFF0E7490),
        ),
        ShiftStatus.restrictedHoliday => (
          label: 'Restricted Holiday',
          color: Color(0xFFB91C1C),
        ),
        ShiftStatus.wfh => (label: 'Work from Home', color: Color(0xFFA3A300)),
        ShiftStatus.wfhOnRequest => (
          label: 'Work from Home on Request',
          color: Color(0xFFCA8A04),
        ),
      };

  static String _fmtHours(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurf = theme.colorScheme.onSurface;
    final meta = _statusMeta(log.status);

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
                  style: AppTextStyle.extraBold
                      .normal(onSurf)
                      .copyWith(fontSize: 20.sdp),
                ),
                Text(
                  _dayAbbrs[log.date.weekday - 1],
                  style: AppTextStyle.normal.small(onSurf.withOpacity(0.45)),
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
                    Icon(
                      PhosphorIcons.briefcase(),
                      size: 13.sdp,
                      color: onSurf.withOpacity(0.45),
                    ),
                    SizedBox(width: 4.sdp),
                    Text(
                      log.shiftName,
                      style: AppTextStyle.bold
                          .normal(onSurf)
                          .copyWith(fontSize: 14.sdp),
                    ),
                  ],
                ),
                SizedBox(height: 3.sdp),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.clock(),
                      size: 13.sdp,
                      color: onSurf.withOpacity(0.35),
                    ),
                    SizedBox(width: 4.sdp),
                    Text(
                      log.shiftTiming,
                      style: AppTextStyle.normal.small(onSurf.withOpacity(0.5)),
                    ),
                  ],
                ),
                SizedBox(height: 6.sdp),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sdp,
                    vertical: 2.sdp,
                  ),
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
                  style: AppTextStyle.extraBold
                      .normal(onSurf)
                      .copyWith(fontSize: 16.sdp),
                ),
                Text(
                  'Hrs',
                  style: AppTextStyle.normal.small(onSurf.withOpacity(0.45)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
