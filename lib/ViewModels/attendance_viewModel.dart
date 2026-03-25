// features/attendance/viewmodel/attendance_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../Models/attendance_shiftLog.dart';


// ── Punch state ───────────────────────────────────────────────────────────────

final attendanceProvider =
StateNotifierProvider<AttendanceNotifier, AttendanceState>(
      (_) => AttendanceNotifier(),
);

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState());

  void togglePunch() {
    final now = DateTime.now();
    state = state.isCheckedIn
        ? state.copyWith(isCheckedIn: false, punchOutTime: now)
        : state.copyWith(isCheckedIn: true, punchInTime: now, punchOutTime: null);
  }
}

// ── Timer stream — isolated so only TimerDisplayRow rebuilds every second ─────

final timerProvider = StreamProvider.autoDispose<Duration>((ref) async* {
  final s = ref.watch(attendanceProvider);

  if (s.isCheckedIn && s.punchInTime != null) {
    yield DateTime.now().difference(s.punchInTime!);
    yield* Stream.periodic(
      const Duration(seconds: 1),
          (_) => DateTime.now().difference(s.punchInTime!),
    );
  } else if (s.punchInTime != null && s.punchOutTime != null) {
    yield s.punchOutTime!.difference(s.punchInTime!); // freeze on check-out
  } else {
    yield Duration.zero;
  }
});

// ── Schedule data — swap body for real repository call ────────────────────────

Duration _calculateDuration(String timing) {
  if (timing.contains('--')) return Duration.zero;

  final parts = timing.split(' to ');
  if (parts.length != 2) return Duration.zero;

  DateTime parse(String t) {
    final now = DateTime.now();
    final format = RegExp(r'(\d+):(\d+)\s?(AM|PM)');
    final match = format.firstMatch(t.trim());
    if (match == null) return now;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPM = match.group(3) == 'PM';

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  final start = parse(parts[0]);
  final end   = parse(parts[1]);

  return end.difference(start);
}

final scheduleProvider = Provider<List<ShiftLog>>((ref) {
  final today  = DateTime.now();
  final monday = today.subtract(Duration(days: today.weekday - 1));

  const statusMap = {
    DateTime.monday:    ShiftStatus.working,
    DateTime.tuesday:   ShiftStatus.dayLeave,
    DateTime.wednesday: ShiftStatus.shortLeave,
    DateTime.thursday:  ShiftStatus.earnedLeave,
    DateTime.friday:    ShiftStatus.emergencyLeave,
    DateTime.saturday:  ShiftStatus.working,
    DateTime.sunday:    ShiftStatus.weekend,
  };

  // 🕒 Slight variations ~8h 30m–8h 50m
  const shiftTimings = {
    DateTime.monday:    ('09:45 AM', '06:20 PM'), // 8h 35m
    DateTime.tuesday:   ('10:00 AM', '06:40 PM'), // 8h 40m
    DateTime.wednesday: ('09:30 AM', '06:10 PM'), // 8h 40m
    DateTime.thursday:  ('10:15 AM', '06:55 PM'), // 8h 40m
    DateTime.friday:    ('09:50 AM', '06:30 PM'), // 8h 40m
    DateTime.saturday:  ('10:10 AM', '06:40 PM'), // 8h 30m
    DateTime.sunday:    ('--', '--'),
  };

  return List.generate(7, (i) {
    final date    = monday.add(Duration(days: i));
    final isToday = date.year  == today.year &&
        date.month == today.month &&
        date.day   == today.day;
    final isPast  = date.isBefore(today) && !isToday;

    final timing = shiftTimings[date.weekday]!;

    return ShiftLog(
      date: date,
      shiftName: 'General Shift',
      shiftTiming: '${timing.$1} to ${timing.$2}',
      status: statusMap[date.weekday] ?? ShiftStatus.working,
      totalHours: isPast
          ? _calculateDuration('${timing.$1} to ${timing.$2}')
          : null,
    );
  });
});

//clock provider
final clockProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    final now = DateTime.now();
    yield now;

    // wait until next minute boundary (not just 60 sec)
    final secondsToNextMinute = 60 - now.second;
    await Future.delayed(Duration(seconds: secondsToNextMinute));
  }
});