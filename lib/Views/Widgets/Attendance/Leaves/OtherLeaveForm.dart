import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../Models/attendance_shiftLog.dart';
import '../../../../Services/snackBar_Service.dart';
import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/leave_viewModel.dart';
import 'LeaveFormComponents.dart';

class OtherLeaveForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const OtherLeaveForm({
    super.key,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  ConsumerState<OtherLeaveForm> createState() => _OtherLeaveFormState();
}

class _OtherLeaveFormState extends ConsumerState<OtherLeaveForm> {
  late DateTime _fromDate = DateTime.now();
  DateTime? _toDate;
  final TextEditingController _reasonController = TextEditingController();
  LeaveDuration _selectedDuration = LeaveDuration.full;
  LeaveFraction? _selectedFraction;
  // --- Restricted Holiday State ---
  ({String name, DateTime date})? _selectedRestrictedHoliday;

  // Hardcoded list with dates for the current year (Will be fetched from API later)
  final List<({String name, DateTime date})> _restrictedHolidays = [
    (name: 'Makar Sankranti', date: DateTime(DateTime.now().year, 1, 14)),
    (name: 'Maha Shivaratri', date: DateTime(DateTime.now().year, 2, 15)),
    (name: 'Holi', date: DateTime(DateTime.now().year, 3, 3)),
    (name: 'Eid al-Fitr', date: DateTime(DateTime.now().year, 3, 20)),
    (name: 'Raksha Bandhan', date: DateTime(DateTime.now().year, 8, 28)),
    (name: 'Karwa Chauth', date: DateTime(DateTime.now().year, 10, 30)),
  ];

  final List<ShiftStatus> _leaveTypes = [
    ShiftStatus.birthdayLeave,
    ShiftStatus.casualLeave,
    ShiftStatus.compOff,
    ShiftStatus.dayLeave,
    ShiftStatus.earnedLeave,
    ShiftStatus.restrictedHoliday,
    ShiftStatus.emergencyLeave,
    ShiftStatus.flexibleSaturday,
  ];

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final type = ref.read(leaveViewModelProvider).selectedLeaveType;
    if (type == null || _reasonController.text.trim().isEmpty) return false;
    if (type == ShiftStatus.restrictedHoliday && _selectedRestrictedHoliday == null) return false;

    if (_selectedDuration == LeaveDuration.full) return _toDate != null;
    return _selectedFraction != null;
  }

  bool get _showsDurationControls {
    final type = ref.read(leaveViewModelProvider).selectedLeaveType;
    return type == ShiftStatus.casualLeave ||
        type == ShiftStatus.earnedLeave ||
        type == ShiftStatus.emergencyLeave;
  }

  bool get _allowsQuarterLeaves {
    return ref.read(leaveViewModelProvider).selectedLeaveType == ShiftStatus.emergencyLeave;
  }

  void _handleTypeChange(ShiftStatus? val) {
    ref.read(leaveViewModelProvider.notifier).setSelectedType(val);

    setState(() {
      _selectedDuration = LeaveDuration.full;
      _selectedFraction = null;
    });
    if (val != ShiftStatus.restrictedHoliday) {
      _fromDate = DateTime.now();
      _toDate = null;
    }
  }

  void _handleCancel() {
    ref.read(leaveViewModelProvider.notifier).setSelectedType(null);
    setState(() {
      _fromDate = DateTime.now();
      _toDate = null;
      _selectedDuration = LeaveDuration.full;
      _selectedFraction = null;
      _selectedRestrictedHoliday = null;
      _reasonController.clear();
    });
    widget.onCancel();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    final type = ref.read(leaveViewModelProvider).selectedLeaveType;

    ref.read(leaveViewModelProvider.notifier).applyOtherLeave(
      type: type!,
      fromDate: _fromDate,
      toDate: _selectedDuration == LeaveDuration.full ? _toDate : null,
      durationType: _selectedDuration,
      fraction: _selectedFraction,
      restrictedHolidayName: type == ShiftStatus.restrictedHoliday ? _selectedRestrictedHoliday?.name : null,
      reason: _reasonController.text.trim(),
    );
  }

  double? _calculateDays() {
    if (_selectedDuration == LeaveDuration.half) return 0.5;
    if (_selectedDuration == LeaveDuration.quarter) return 0.25;
    if (_toDate == null) return null;
    return (_toDate!.difference(_fromDate).inDays + 1).toDouble();
  }

  String _formatDuration(double days) {
    final val = days % 1 == 0 ? days.toInt().toString() : days.toString();
    return "$val ${days <= 1 ? 'Day' : 'Days'}";
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveViewModelProvider);

    ref.listen<LeaveState>(leaveViewModelProvider, (previous, next) {
      if (next.status == LeaveSubmitState.error && next.errorMessage != null) {
        SnackbarService.showError(next.errorMessage!);
        ref.read(leaveViewModelProvider.notifier).resetState();
      } else if (next.status == LeaveSubmitState.success) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) widget.onSuccess();
        });
      }
    });

    final primaryBlue = LeaveFormStyles.primaryBlue(context);
    final textAdaptive = LeaveFormStyles.textAdaptive(context);
    final days = _calculateDays();

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.sdp),
        DropdownButtonFormField<ShiftStatus>(
          value: leaveState.selectedLeaveType,
          icon: Icon(PhosphorIcons.caretDown(), color: primaryBlue, size: 20.sdp),
          decoration: LeaveFormStyles.baseDecoration(context, "Leave Type"),
          items: _leaveTypes.map((type) {
            final meta = type.meta;
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Container(width: 12.sdp, height: 12.sdp, decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle)),
                  SizedBox(width: 14.sdp),
                  Text(meta.label, style: AppTextStyle.normal.custom(14.ssp, textAdaptive)),
                ],
              ),
            );
          }).toList(),
          onChanged: _handleTypeChange,
        ),

        if (leaveState.selectedLeaveType == ShiftStatus.restrictedHoliday) ...[
          SizedBox(height: 16.sdp),
          DropdownButtonFormField<({String name, DateTime date})>(
            value: _selectedRestrictedHoliday,
            icon: Icon(PhosphorIcons.caretDown(), color: primaryBlue, size: 20.sdp),
            decoration: LeaveFormStyles.baseDecoration(context, "Select Holiday"),
            items: _restrictedHolidays.map((holiday) {
              return DropdownMenuItem(
                value: holiday,
                child: Text(
                    "${holiday.name} (${DateFormat('dd MMM yyyy').format(holiday.date)})",
                    style: AppTextStyle.normal.normal(textAdaptive)
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedRestrictedHoliday = val;
                  // Auto-fill dates based on selected holiday
                  _fromDate = val.date;
                  _toDate = val.date;
                  _selectedDuration = LeaveDuration.full;
                });
              }
            },
          ),
        ],

        // --- Dynamic Duration Selectors ---
        if (_showsDurationControls) ...[
          SizedBox(height: 16.sdp),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<LeaveDuration>(
                  value: _selectedDuration,
                  icon: Icon(PhosphorIcons.caretDown(), color: primaryBlue, size: 20.sdp),
                  decoration: LeaveFormStyles.baseDecoration(context, "Duration"),
                  items: [
                    DropdownMenuItem(value: LeaveDuration.full, child: Text("Full Day", style: AppTextStyle.normal.normal(textAdaptive))),
                    DropdownMenuItem(value: LeaveDuration.half, child: Text("Half Day", style: AppTextStyle.normal.normal(textAdaptive))),
                    if (_allowsQuarterLeaves)
                      DropdownMenuItem(value: LeaveDuration.quarter, child: Text("Quarter Day", style: AppTextStyle.normal.normal(textAdaptive))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDuration = val;
                        _selectedFraction = null;
                      });
                    }
                  },
                ),
              ),
              if (_selectedDuration != LeaveDuration.full) ...[
                SizedBox(width: 16.sdp),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<LeaveFraction>(
                    value: _selectedFraction,
                    icon: Icon(PhosphorIcons.caretDown(), color: primaryBlue, size: 20.sdp),
                    decoration: LeaveFormStyles.baseDecoration(context, _selectedDuration == LeaveDuration.half ? "Which Half?" : "Which Quarter?"),
                    items: _selectedDuration == LeaveDuration.half
                        ? [
                      DropdownMenuItem(value: LeaveFraction.firstHalf, child: Text("1st Half", style: AppTextStyle.normal.normal(textAdaptive))),
                      DropdownMenuItem(value: LeaveFraction.secondHalf, child: Text("2nd Half", style: AppTextStyle.normal.normal(textAdaptive))),
                    ]
                        : [
                      DropdownMenuItem(value: LeaveFraction.q1, child: Text("1st Qtr", style: AppTextStyle.normal.normal(textAdaptive))),
                      DropdownMenuItem(value: LeaveFraction.q2, child: Text("2nd Qtr", style: AppTextStyle.normal.normal(textAdaptive))),
                      DropdownMenuItem(value: LeaveFraction.q3, child: Text("3rd Qtr", style: AppTextStyle.normal.normal(textAdaptive))),
                      DropdownMenuItem(value: LeaveFraction.q4, child: Text("4th Qtr", style: AppTextStyle.normal.normal(textAdaptive))),
                    ],
                    onChanged: (val) => setState(() => _selectedFraction = val),
                  ),
                ),
              ]
            ],
          ),
        ],

        SizedBox(height: 16.sdp),

        // --- Date Pickers ---
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                style: AppTextStyle.normal.normal(textAdaptive),
                decoration: LeaveFormStyles.baseDecoration(
                  context,
                  _selectedDuration == LeaveDuration.full ? "From Date" : "Date",
                  suffixIcon: Icon(PhosphorIcons.calendarBlank(), color: primaryBlue, size: 20.sdp),
                ),
                controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_fromDate)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _fromDate = picked);
                },
              ),
            ),
            if (_selectedDuration == LeaveDuration.full) ...[
              SizedBox(width: 16.sdp),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  style: AppTextStyle.normal.normal(textAdaptive),
                  decoration: LeaveFormStyles.baseDecoration(
                    context,
                    "To Date",
                    suffixIcon: Icon(PhosphorIcons.calendarBlank(), color: primaryBlue, size: 20.sdp),
                  ),
                  controller: TextEditingController(text: _toDate != null ? DateFormat('dd/MM/yyyy').format(_toDate!) : ""),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? _fromDate,
                      firstDate: _fromDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _toDate = picked);
                  },
                ),
              ),
            ]
          ],
        ),

        SizedBox(height: 15.sdp),
        if (days != null)
          LeaveDurationIndicator(duration: _formatDuration(days), icon: PhosphorIcons.calendarPlus()),
        TextFormField(
          controller: _reasonController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: AppTextStyle.normal.normal(textAdaptive),
          decoration: LeaveFormStyles.baseDecoration(context, "Reason for leave").copyWith(
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.all(16.sdp),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 32.sdp),
        LeaveActionButtons(
          onDiscard: _handleCancel,
          onApply: _isFormValid ? _submitForm : null,
        ),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: leaveState.status == LeaveSubmitState.editing ? 1.0 : 0.0,
          child: IgnorePointer(ignoring: leaveState.status != LeaveSubmitState.editing, child: formContent),
        ),
        if (leaveState.status == LeaveSubmitState.loading) CircularProgressIndicator(color: primaryBlue),
        if (leaveState.status == LeaveSubmitState.success)
          LeaveSuccessView(
            message: "${leaveState.selectedLeaveType?.meta.label ?? 'Leave'} applied successfully\nfor ${days != null ? _formatDuration(days) : ''}",
          ),
      ],
    );
  }
}