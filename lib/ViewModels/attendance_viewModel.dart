// features/attendance/viewmodel/attendance_providers.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import '../API/attendance_apiService.dart';
import '../Models/attendance_shiftLog.dart';

// ── Punch state ───────────────────────────────────────────────────────────────

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>(
      (_) => AttendanceNotifier(),
    );

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState());

  Future<void> fetchLiveStatus() async {
    try {
      final res = await AttendanceApiService.fetchLiveAttendance();
      final data = res['data'];

      if (data != null) {
        final isCheckedIn = data['isCheckedIn'] ?? false;
        final isOnWFH = data['isOnWFH'] ?? data['isWFH'] ?? false;
        final punches = data['punches'] as List<dynamic>? ?? [];
        final now = DateTime.now();

        DateTime? firstPunchIn;
        DateTime? lastPunchOut;
        Duration actualWork = Duration.zero;
        DateTime? openPunchIn; // tracks an unmatched 'in'
        final List<PunchEntry> parsedPunches = [];

        for (final punch in punches) {
          final type = punch['type'] as String;
          final timeParts = (punch['time'] as String).split(':');
          final punchTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            int.parse(timeParts[2]),
          );

          parsedPunches.add(PunchEntry(type: type, time: punchTime));

          if (type == 'in') {
            openPunchIn ??= punchTime;
            firstPunchIn ??= punchTime;
            openPunchIn = punchTime; // always update to latest 'in'
          } else if (type == 'out' && openPunchIn != null) {
            actualWork += punchTime.difference(openPunchIn); // add segment
            lastPunchOut = punchTime;
            openPunchIn = null; // segment closed
          }
        }

        // If still checked in, openPunchIn holds the last unmatched 'in'
        // We DON'T add live time here — the timerProvider handles that reactively

        state = AttendanceState(
          isCheckedIn: isCheckedIn,
          isOnWFH: isOnWFH,
          punchInTime: openPunchIn,
          punchOutTime: lastPunchOut,
          firstPunchInTime: firstPunchIn,
          actualWorkDuration: actualWork,
          punches: parsedPunches,
        );
      }
    } catch (e) {
      debugPrint("Failed to fetch live attendance status: $e");
      SnackbarService.showError("Failed to update attendance. Error $e");
    }
  }

  // Handle Check-in / Check-out API calls
  Future<void> togglePunch({required Map<String, dynamic>? location}) async {
    final payload = {"deviceId": "mobile_device", "location": location};

    try {
      if (state.isCheckedIn) {
        await AttendanceApiService.checkOut(payload);
        SnackbarService.showSuccess("Checked-out Successfully");
      } else {
        await AttendanceApiService.checkIn(payload);
        SnackbarService.showSuccess("Checked-in Successfully");
      }

      // Refresh state from server to ensure perfect sync
      await fetchLiveStatus();
    } catch (e) {
      debugPrint("Punch operation failed: $e");
      SnackbarService.showError("Error: $e");
    }
  }
}

// ── Timer stream — isolated so only TimerDisplayRow rebuilds every second ─────

// attendance_providers.dart
// Updated timerProvider — emits: accumulated + live elapsed (if checked in)
final timerProvider = StreamProvider.autoDispose<Duration>((ref) {
  final s = ref.watch(attendanceProvider);
  final accumulated = s.actualWorkDuration;

  if (s.isCheckedIn && s.punchInTime != null) {
    // Live: closed segments + time since last punch-in
    return _wallClockAlignedTimer(s.punchInTime!, accumulated);
  } else {
    // Checked out: just show the total closed segments
    return Stream.value(accumulated);
  }
});

Stream<Duration> _wallClockAlignedTimer(
  DateTime lastPunchIn,
  Duration accumulated,
) async* {
  Duration live() => accumulated + DateTime.now().difference(lastPunchIn);

  yield live();

  final msUntilNextSecond = 1000 - DateTime.now().millisecond;
  await Future.delayed(Duration(milliseconds: msUntilNextSecond));
  yield live();

  yield* Stream.periodic(const Duration(seconds: 1), (_) => live());
}

//work schedule provider
final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<ShiftLog>>>((ref) {
      return ScheduleNotifier()..fetchWeek(DateTime.now());
    });

class ScheduleNotifier extends StateNotifier<AsyncValue<List<ShiftLog>>> {
  ScheduleNotifier() : super(const AsyncValue.loading());

  /// The Monday of the currently displayed week.
  DateTime currentMonday = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  Future<void> fetchCurrentWeek() => fetchWeek(DateTime.now());

  Future<void> fetchWeek(DateTime anyDayInWeek) async {
    state = const AsyncValue.loading();
    try {
      final today = DateTime.now();
      final monday = anyDayInWeek.subtract(
        Duration(days: anyDayInWeek.weekday - 1),
      );
      final saturday = monday.add(const Duration(days: 5));

      // Track which week is displayed so the UI can read it
      currentMonday = monday;

      final fromStr = monday.toIso8601String().substring(0, 10);
      final toStr = saturday.toIso8601String().substring(0, 10);

      final response = await AttendanceApiService.fetchWorkScheduleSummary(
        from: fromStr,
        to: toStr,
      );

      final summaries = response['summaries'] as List<dynamic>? ?? [];

      // Build a lookup map: "YYYY-MM-DD" → summary object
      final summaryMap = <String, dynamic>{
        for (final s in summaries) (s['date'] as String).substring(0, 10): s,
      };

      // Always generate Mon–Sat, merge API data where it exists
      final logs = List.generate(6, (i) {
        final date = monday.add(Duration(days: i));
        final dateStr = date.toIso8601String().substring(0, 10);
        final summary = summaryMap[dateStr]; // null if no record yet

        final totalMins = summary?['totalDurationMinutes'] as int? ?? 0;
        final statusStr = summary?['status'] as String?;
        final leaveType = summary?['leaveType'] as String?;
        final firstCheckIn =
            summary?['firstCheckIn'] as String? ??
            summary?['first_check_in'] as String?;
        final lastCheckOut =
            summary?['lastCheckOut'] as String? ??
            summary?['last_checkout'] as String? ??
            summary?['last_check_out'] as String?;

        final isPastOrToday = !date.isAfter(today);
        final shiftTiming = _formatShiftTiming(firstCheckIn, lastCheckOut);

        return ShiftLog(
          date: date,
          shiftName: 'General Shift',
          shiftTiming: shiftTiming,
          // Prioritize API status regardless of date; fallback to working if null
          status: _parseShiftStatus(statusStr, leaveType),
          // Only show hours for past days that have a summary with duration
          totalHours: (isPastOrToday && totalMins > 0)
              ? Duration(minutes: totalMins)
              : null,
        );
      });

      logs.sort((a, b) => a.date.compareTo(b.date));
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      debugPrint('[ScheduleNotifier] err: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  static const String _defaultShiftStart = '10:00 AM';
  static const String _defaultShiftEnd = '06:30 PM';

  String _formatShiftTiming(String? firstCheckIn, String? lastCheckOut) {
    final start = _normalizeShiftTime(firstCheckIn) ?? _defaultShiftStart;
    final end = _normalizeShiftTime(lastCheckOut) ?? _defaultShiftEnd;
    return '$start to $end';
  }

  String? _normalizeShiftTime(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // Maps backend strings directly to our ShiftStatus enum
  ShiftStatus _parseShiftStatus(String? status, String? leaveType) {
    if (status == null) return ShiftStatus.working;

    switch (status) {
      case 'Present':
        return ShiftStatus.working;
      case 'HalfDay':
        return ShiftStatus.halfDay;
      case 'Weekend':
        return ShiftStatus.weekend;
      case 'Absent':
        return ShiftStatus.absent;
      case 'OnLeave':
        if (leaveType == null) return ShiftStatus.dayLeave;

        final lower = leaveType.toLowerCase();
        if (lower.contains('casual')) return ShiftStatus.casualLeave;
        if (lower.contains('emergency')) return ShiftStatus.emergencyLeave;
        if (lower.contains('short') || lower.contains('half'))
          return ShiftStatus.shortLeave;
        if (lower.contains('birthday')) return ShiftStatus.birthdayLeave;
        if (lower.contains('comp')) return ShiftStatus.compOff;
        if (lower.contains('earned')) return ShiftStatus.earnedLeave;
        if (lower.contains('restricted')) return ShiftStatus.restrictedHoliday;
        if (lower.contains('flexible')) return ShiftStatus.flexibleSaturday;
        if (lower.contains('meeting')) return ShiftStatus.meeting;
        if (lower.contains('request')) return ShiftStatus.wfhOnRequest;
        if (lower.contains('wfh') || lower.contains('home'))
          return ShiftStatus.wfh;

        return ShiftStatus.dayLeave;
      default:
        // Use lowercase check for robustness against backend variation
        final lowerStatus = status.toLowerCase();
        if (lowerStatus == 'present') return ShiftStatus.working;
        if (lowerStatus == 'halfday' || lowerStatus.contains('half'))
          return ShiftStatus.halfDay;

        return ShiftStatus.working;
    }
  }
}

//clock provider
// final clockProvider = StreamProvider<DateTime>((ref) async* {
//   while (true) {
//     final now = DateTime.now();
//     yield now;
//
//     // wait until next minute boundary (not just 60 sec)
//     final secondsToNextMinute = 60 - now.second;
//     await Future.delayed(Duration(seconds: secondsToNextMinute));
//   }
// });
