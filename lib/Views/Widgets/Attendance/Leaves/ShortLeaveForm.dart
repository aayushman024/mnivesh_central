import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../Services/snackBar_Service.dart';
import '../../../../ViewModels/leave_viewModel.dart';
import 'LeaveFormComponents.dart';

class ShortLeaveForm extends ConsumerStatefulWidget {
  final int balanceHours;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const ShortLeaveForm({
    super.key,
    required this.balanceHours,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  ConsumerState<ShortLeaveForm> createState() => _ShortLeaveFormState();
}

class _ShortLeaveFormState extends ConsumerState<ShortLeaveForm> {
  late DateTime _selectedDate = DateTime.now();
  late TimeOfDay _fromTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _toTime;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _fromTimeCtrl = TextEditingController();
  final TextEditingController _toTimeCtrl = TextEditingController();

  bool _didInitTimes = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitTimes) {
      _didInitTimes = true;
      _fromTimeCtrl.text = _fromTime.format(context);
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _fromTimeCtrl.dispose();
    _toTimeCtrl.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _toTime != null && _reasonController.text.trim().isNotEmpty;

  void _handleCancel() {
    widget.onCancel();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(leaveViewModelProvider.notifier).applyShortLeave(
      date: _selectedDate,
      from: _fromTime,
      to: _toTime!,
      reason: _reasonController.text.trim(),
      balanceHours: widget.balanceHours,
    );
  }

  String? _calculateDuration() {
    if (_toTime == null) return null;

    final now = DateTime.now();
    final fromDt = DateTime(now.year, now.month, now.day, _fromTime.hour, _fromTime.minute);
    final toDt = DateTime(now.year, now.month, now.day, _toTime!.hour, _toTime!.minute);

    final difference = toDt.difference(fromDt);
    if (difference.isNegative || difference.inMinutes == 0) return null;

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) return "${hours} hr ${minutes > 0 ? '$minutes min' : ''}";
    return "$minutes min";
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
    final duration = _calculateDuration();

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24.sdp),
        TextFormField(
          readOnly: true,
          style: AppTextStyle.normal.normal(textAdaptive),
          decoration: LeaveFormStyles.baseDecoration(
            context,
            "Date",
            suffixIcon: Icon(PhosphorIcons.calendarBlank(), color: primaryBlue, size: 20.sdp),
          ),
          controller: _dateCtrl,
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
            }
          },
        ),
        SizedBox(height: 16.sdp),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                style: AppTextStyle.normal.normal(textAdaptive),
                decoration: LeaveFormStyles.baseDecoration(
                  context,
                  "Start Time",
                  suffixIcon: Icon(PhosphorIcons.clock(), color: primaryBlue, size: 20.sdp),
                ),
                controller: _fromTimeCtrl,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: _fromTime);
                  if (picked != null) {
                    setState(() => _fromTime = picked);
                    _fromTimeCtrl.text = picked.format(context);
                  }
                },
              ),
            ),
            SizedBox(width: 16.sdp),
            Expanded(
              child: TextFormField(
                readOnly: true,
                style: AppTextStyle.normal.normal(textAdaptive),
                decoration: LeaveFormStyles.baseDecoration(
                  context,
                  "End Time",
                  suffixIcon: Icon(PhosphorIcons.clock(), color: primaryBlue, size: 20.sdp),
                ),
                controller: _toTimeCtrl,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: _toTime ?? _fromTime);
                  if (picked != null) {
                    setState(() => _toTime = picked);
                    _toTimeCtrl.text = picked.format(context);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 15.sdp),
        if (duration != null)
          LeaveDurationIndicator(duration: duration, icon: PhosphorIcons.timer()),
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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _reasonController,
          builder: (_, __, ___) => LeaveActionButtons(
            onDiscard: _handleCancel,
            onApply: _isFormValid ? _submitForm : null,
          ),
        ),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: leaveState.status == LeaveSubmitState.editing ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: leaveState.status != LeaveSubmitState.editing,
            child: formContent,
          ),
        ),
        if (leaveState.status == LeaveSubmitState.loading) CircularProgressIndicator(color: primaryBlue),
        if (leaveState.status == LeaveSubmitState.success)
          LeaveSuccessView(message: "Short leave applied successfully\nfor ${duration ?? ''}"),
      ],
    );
  }
}