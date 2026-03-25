// features/attendance/model/attendance_state.dart

class AttendanceState {
  final bool isCheckedIn;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;

  const AttendanceState({
    this.isCheckedIn = false,
    this.punchInTime,
    this.punchOutTime,
  });

  AttendanceState copyWith({
    bool? isCheckedIn,
    DateTime? punchInTime,
    DateTime? punchOutTime,
  }) =>
      AttendanceState(
        isCheckedIn:  isCheckedIn  ?? this.isCheckedIn,
        punchInTime:  punchInTime  ?? this.punchInTime,
        punchOutTime: punchOutTime ?? this.punchOutTime,
      );
}

// features/attendance/model/shift_log.dart

enum ShiftStatus {
  weekend,
  working,
  casualLeave,
  absent,
  emergencyLeave,
  shortLeave,
  birthdayLeave,
  compOff,
  dayLeave,
  earnedLeave,
  flexibleSaturday,
  meeting,
  restrictedHoliday,
  wfh,
  wfhOnRequest,
}

class ShiftLog {
  final DateTime date;
  final String shiftName;
  final String shiftTiming;
  final ShiftStatus status;

  /// null → today or future (hours column is hidden)
  final Duration? totalHours;

  const ShiftLog({
    required this.date,
    required this.shiftName,
    required this.shiftTiming,
    required this.status,
    this.totalHours,
  });
}