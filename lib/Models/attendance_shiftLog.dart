// features/attendance/model/attendance_state.dart

import 'dart:ui';

import 'package:flutter/material.dart';

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

// Assuming your enum is defined here
enum ShiftStatus {
  weekend, working, casualLeave, absent, emergencyLeave, shortLeave,
  birthdayLeave, compOff, dayLeave, earnedLeave, flexibleSaturday,
  meeting, restrictedHoliday, wfh, wfhOnRequest
}

extension ShiftStatusMeta on ShiftStatus {
  ({String label, Color color, double balance}) get meta => switch (this) {
    ShiftStatus.casualLeave => (label: 'Casual Leave', color: const Color(0xFF0F766E), balance: 4.0),
    ShiftStatus.emergencyLeave => (label: 'Emergency Leave', color: const Color(0xFFB91C1C), balance: 2.0),
    ShiftStatus.birthdayLeave => (label: 'Birthday Leave', color: const Color(0xFF0EA5A4), balance: 1.0),
    ShiftStatus.compOff => (label: 'Compensatory Off', color: const Color(0xFFB45309), balance: 3.5),
    ShiftStatus.dayLeave => (label: 'Day Leave', color: const Color(0xFF777F04), balance: 8.0),
    ShiftStatus.earnedLeave => (label: 'Earned Leave', color: const Color(0xFF166534), balance: 12.0),
    ShiftStatus.restrictedHoliday => (label: 'Restricted Holiday', color: const Color(0xFFB91C1C), balance: 2.0),
    ShiftStatus.flexibleSaturday => (label: 'Flexible Saturday', color: const Color(0xFFD97706), balance: 1.0),
    ShiftStatus.meeting => (label: 'Meeting with Client', color: const Color(0xFF0E7490), balance: 0.0),
    ShiftStatus.wfh => (label: 'Work from Home', color: const Color(0xFFA3A300), balance: 5.0),
    ShiftStatus.wfhOnRequest => (label: 'Work from Home on Request', color: const Color(0xFFCA8A04), balance: 2.0),
    _ => (label: name, color: Colors.grey, balance: 0.0), // Fallback
  };
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
