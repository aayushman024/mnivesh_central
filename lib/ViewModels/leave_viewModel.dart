import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../Models/attendance_shiftLog.dart';
import '../API/attendance_apiService.dart';

enum LeaveSubmitState { editing, loading, success, error }
enum LeaveDuration { full, half, quarter }
enum LeaveFraction { firstHalf, secondHalf, q1, q2, q3, q4 }

class LeaveState {
  final LeaveSubmitState status;
  final String? errorMessage;
  final ShiftStatus? selectedLeaveType;
  final Map<String, dynamic>? summaryData;

  const LeaveState({
    this.status = LeaveSubmitState.editing,
    this.errorMessage,
    this.selectedLeaveType,
    this.summaryData,
  });

  LeaveState copyWith({
    LeaveSubmitState? status,
    String? errorMessage,
    ShiftStatus? selectedLeaveType,
    bool clearLeaveType = false,
    Map<String, dynamic>? summaryData,
  }) {
    return LeaveState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedLeaveType: clearLeaveType ? null : (selectedLeaveType ?? this.selectedLeaveType),
      summaryData: summaryData ?? this.summaryData,
    );
  }
}

final leaveViewModelProvider = StateNotifierProvider<LeaveViewModel, LeaveState>((ref) {
  return LeaveViewModel();
});

class LeaveViewModel extends StateNotifier<LeaveState> {
  LeaveViewModel() : super(const LeaveState());

  void resetState() {
    state = LeaveState(summaryData: state.summaryData); // Retain summary data when resetting
  }

  void setSelectedType(ShiftStatus? type) {
    if (type == null) {
      state = state.copyWith(clearLeaveType: true);
    } else {
      state = state.copyWith(selectedLeaveType: type);
    }
  }

  Future<void> fetchLeaveSummary() async {
    try {
      final res = await AttendanceApiService.fetchLeaveSummary();
      final data = res['data'];
      
      if (data != null && data is Map<String, dynamic>) {
        state = state.copyWith(summaryData: data);
        print("LEAVE DATA $data");
      }
    } catch (e) {
      debugPrint("Failed to fetch leave summary: $e");
    }
  }

  Future<void> applyShortLeave({
    required int balanceHours,
    required DateTime date,
    required TimeOfDay from,
    required TimeOfDay to,
    required String reason,
  }) async {
    final now = DateTime.now();
    final fromDt = DateTime(now.year, now.month, now.day, from.hour, from.minute);
    final toDt = DateTime(now.year, now.month, now.day, to.hour, to.minute);
    final diffMins = toDt.difference(fromDt).inMinutes;

    if (diffMins <= 0) {
      state = state.copyWith(status: LeaveSubmitState.error, errorMessage: "End time must be after start time");
      return;
    }

    if (diffMins > (balanceHours * 60)) {
      state = state.copyWith(status: LeaveSubmitState.error, errorMessage: "Duration exceeds balance ($balanceHours hrs)");
      return;
    }

    state = state.copyWith(status: LeaveSubmitState.loading);
    // TODO: Wire API here
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(status: LeaveSubmitState.success);
  }

  Future<void> applyOtherLeave({
    required ShiftStatus type,
    required DateTime fromDate,
    DateTime? toDate, // Nullable since half/quarter leaves are single day
    required LeaveDuration durationType,
    LeaveFraction? fraction, // Null if full day
    String? restrictedHolidayName,
    required String reason,
  }) async {
    if (durationType == LeaveDuration.full && toDate != null && toDate.isBefore(fromDate)) {
      state = state.copyWith(status: LeaveSubmitState.error, errorMessage: "End date cannot be before start date");
      return;
    }

    state = state.copyWith(status: LeaveSubmitState.loading);
    // TODO: Wire API here. Payload mapping depends on backend specs
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(status: LeaveSubmitState.success);
  }
}