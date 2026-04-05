import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../Services/snackBar_Service.dart';

enum LeaveSubmitState { editing, loading, success }

class ShortLeaveForm extends StatefulWidget {
  final int balanceHours;
  final VoidCallback onCancel;
  final Function(DateTime date, TimeOfDay from, TimeOfDay to, String reason) onApply;

  const ShortLeaveForm({
    super.key,
    required this.balanceHours,
    required this.onCancel,
    required this.onApply,
  });

  @override
  State<ShortLeaveForm> createState() => _ShortLeaveFormState();
}

class _ShortLeaveFormState extends State<ShortLeaveForm> {
  late DateTime _selectedDate = DateTime.now();
  late TimeOfDay _fromTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _toTime;
  final TextEditingController _reasonController = TextEditingController();

  LeaveSubmitState _viewState = LeaveSubmitState.editing;

  @override
  void initState() {
    super.initState();
    // Rebuilds the UI on every keystroke to instantly enable the Apply button
    _reasonController.addListener(_onFormUpdated);
  }

  @override
  void dispose() {
    _reasonController.removeListener(_onFormUpdated);
    _reasonController.dispose();
    super.dispose();
  }

  void _onFormUpdated() {
    setState(() {});
  }

  // Returns true as soon as a single non-whitespace character is entered and time is set
  bool get _isFormValid {
    return _toTime != null && _reasonController.text.trim().isNotEmpty;
  }

  void _handleCancel() {
    setState(() {
      _selectedDate = DateTime.now();
      _fromTime = const TimeOfDay(hour: 10, minute: 0);
      _toTime = null;
      _reasonController.clear();
      _viewState = LeaveSubmitState.editing;
    });
    widget.onCancel();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _validateAndApply() async {
    final now = DateTime.now();
    final fromDt = DateTime(now.year, now.month, now.day, _fromTime.hour, _fromTime.minute);
    final toDt = DateTime(now.year, now.month, now.day, _toTime!.hour, _toTime!.minute);

    final diffMins = toDt.difference(fromDt).inMinutes;

    if (diffMins <= 0) {
      SnackbarService.showError("End time must be after start time");
      return;
    }

    if (diffMins > (widget.balanceHours * 60)) {
      SnackbarService.showError("Duration exceeds balance (${widget.balanceHours} hrs)");
      return;
    }

    // --- Loading State ---
    setState(() => _viewState = LeaveSubmitState.loading);
    FocusManager.instance.primaryFocus?.unfocus();

    // Simulate network delay (Replace/remove this with your actual API call)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // --- Success State ---
    setState(() => _viewState = LeaveSubmitState.success);

    // Wait 2.5 seconds to let the Lottie animation finish and user to read the text
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      // Triggers the Navigator.pop in the parent widget
      widget.onApply(_selectedDate, _fromTime, _toTime!, _reasonController.text.trim());
    }
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

    if (hours > 0) {
      return "${hours} hr ${minutes > 0 ? '$minutes min' : ''}";
    }
    return "$minutes min";
  }

  Widget _buildDurationIndicator(Color primaryBlue, Color textColor) {
    final duration = _calculateDuration();
    if (duration == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.sdp),
      padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 12.sdp),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.timer(), color: primaryBlue, size: 20.sdp),
          SizedBox(width: 12.sdp),
          Text(
            "Total Duration:",
            style: AppTextStyle.normal.small(textColor.withOpacity(0.7)),
          ),
          SizedBox(width: 6.sdp),
          Text(
            duration,
            style: AppTextStyle.bold.small(primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldPicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      style: AppTextStyle.normal.normal(textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyle.normal.small(textColor.withOpacity(0.6)),
        suffixIcon: Icon(icon, color: primaryColor, size: 20.sdp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.sdp),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.sdp),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      controller: TextEditingController(text: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryBlue = isDark ? const Color(0xFF4C9AFF) : const Color(0xFF0052CC);
    final Color textAdaptive = isDark ? const Color(0xFFF4F5F7) : const Color(0xFF172B4D);
    final Color borderSubtle = isDark ? const Color(0xFF344563) : const Color(0xFFDFE1E6);

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24.sdp),
        _buildTextFieldPicker(
          label: "Date",
          value: DateFormat('dd/MM/yyyy').format(_selectedDate),
          icon: PhosphorIcons.calendarBlank(),
          textColor: textAdaptive,
          borderColor: borderSubtle,
          primaryColor: primaryBlue,
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        SizedBox(height: 16.sdp),

        Row(
          children: [
            Expanded(
              child: _buildTextFieldPicker(
                label: "Start Time",
                value: _fromTime.format(context),
                icon: PhosphorIcons.clock(),
                textColor: textAdaptive,
                borderColor: borderSubtle,
                primaryColor: primaryBlue,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _fromTime,
                  );
                  if (picked != null) setState(() => _fromTime = picked);
                },
              ),
            ),
            SizedBox(width: 16.sdp),
            Expanded(
              child: _buildTextFieldPicker(
                label: "End Time",
                value: _toTime != null ? _toTime!.format(context) : "",
                icon: PhosphorIcons.clock(),
                textColor: textAdaptive,
                borderColor: borderSubtle,
                primaryColor: primaryBlue,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _toTime ?? _fromTime,
                  );
                  if (picked != null) {
                    setState(() => _toTime = picked);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 15.sdp),

        _buildDurationIndicator(primaryBlue, textAdaptive),

        TextFormField(
          controller: _reasonController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          style: AppTextStyle.normal.normal(textAdaptive),
          decoration: InputDecoration(
            labelText: "Reason for leave",
            labelStyle: AppTextStyle.normal.small(textAdaptive.withOpacity(0.6)),
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.all(16.sdp),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.sdp),
              borderSide: BorderSide(color: borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.sdp),
              borderSide: BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 32.sdp),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDE350B),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  padding: EdgeInsets.symmetric(vertical: 16.sdp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.sdp),
                  ),
                  side: const BorderSide(color: Color(0xFFDE350B)),
                  elevation: 0,
                ),
                child: Text("Discard", style: AppTextStyle.bold.normal(const Color(0xFFDE350B))),
              ),
            ),
            SizedBox(width: 16.sdp),
            Expanded(
              child: ElevatedButton(
                // Button implicitly enables as soon as _isFormValid returns true
                onPressed: _isFormValid ? _validateAndApply : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: primaryBlue.withOpacity(0.4),
                  disabledForegroundColor: Colors.white.withOpacity(0.7),
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16.sdp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.sdp),
                  ),
                ),
                child: Text("Apply", style: AppTextStyle.bold.normal(Colors.white)),
              ),
            ),
          ],
        )
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Form (Invisible & Un-clickable during loading/success)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _viewState == LeaveSubmitState.editing ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: _viewState != LeaveSubmitState.editing,
            child: formContent,
          ),
        ),

        // Circular Loader overlay
        if (_viewState == LeaveSubmitState.loading)
          CircularProgressIndicator(color: primaryBlue),

        // Success Animation + Text overlay
        if (_viewState == LeaveSubmitState.success)
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://mainstorage01.blob.core.windows.net/android-apps/mNivesh_Central/animations/Success.json',
                width: 150.sdp,
                height: 150.sdp,
                repeat: false,
              ),
              SizedBox(height: 26.sdp),
              Text(
                "Short leave applied successfully\nfor ${_calculateDuration() ?? ''}",
                style: AppTextStyle.bold.normal(textAdaptive),
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ],
    );
  }
}