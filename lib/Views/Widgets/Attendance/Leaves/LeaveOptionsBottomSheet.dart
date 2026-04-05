import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Utils/DismissKeyboard.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Models/attendance_shiftLog.dart';
import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/leave_viewModel.dart';
import 'ShortLeaveForm.dart';
import 'OtherLeaveForm.dart';

enum ActiveForm { none, shortLeave, otherLeave }

class LeaveOptionsSheet extends ConsumerStatefulWidget {
  const LeaveOptionsSheet({super.key});

  @override
  ConsumerState<LeaveOptionsSheet> createState() => _LeaveOptionsSheetState();
}

class _LeaveOptionsSheetState extends ConsumerState<LeaveOptionsSheet> {
  ActiveForm _activeForm = ActiveForm.none;
  final int _balanceHours = 8;
  // final int _balanceLeaves = 12;

  void _openForm(ActiveForm form) {
    if (_activeForm == form) return;
    setState(() => _activeForm = form);
  }

  void _closeForm() {
    if (_activeForm == ActiveForm.none) return;
    ref.read(leaveViewModelProvider.notifier).setSelectedType(null);
    setState(() => _activeForm = ActiveForm.none);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16.sdp,
        left: 16.sdp,
        right: 16.sdp,
        top: 1.sdp,
      ),
      child: DismissKeyboard(
        child: SingleChildScrollView(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _activeForm != ActiveForm.none
                  ? _buildExpandedFormContainer(key: const ValueKey('expanded_view'))
                  : _buildCollapsedMenu(isDark, key: const ValueKey('collapsed_view')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedMenu(bool isDark, {required Key key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SheetItem(
          icon: PhosphorIcons.files(),
          color: Colors.deepPurpleAccent,
          label: "View Leaves",
          onTap: () => Navigator.pop(context),
        ),
        _VerticalDivider(isDark: isDark),
        _SheetItem(
          icon: PhosphorIcons.calendarPlus(),
          color: Colors.orange,
          label: "Other Leaves",
          onTap: () => _openForm(ActiveForm.otherLeave),
        ),
        _VerticalDivider(isDark: isDark),
        _SheetItem(
          icon: PhosphorIcons.clock(),
          color: Colors.green,
          label: "Short Leave",
          onTap: () => _openForm(ActiveForm.shortLeave),
        ),
      ],
    );
  }

  Widget _buildExpandedFormContainer({required Key key}) {
    return ConstrainedBox(
      key: key,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          SizedBox(height: 16.sdp),
          Flexible(
            child: SingleChildScrollView(
              child: _activeForm == ActiveForm.shortLeave
                  ? ShortLeaveForm(
                balanceHours: _balanceHours,
                onCancel: _closeForm,
                onSuccess: () => Navigator.pop(context), // Pops sheet after animation
              )
                  : OtherLeaveForm(
                onCancel: _closeForm,
                onSuccess: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final leaveState = ref.watch(leaveViewModelProvider); // Listen to State
    final isShort = _activeForm == ActiveForm.shortLeave;

    Widget? balancePill;

    // Conditionally assemble the balance pill
    if (isShort) {
      balancePill = _buildPillWidget("Balance: $_balanceHours hrs");
    } else if (leaveState.selectedLeaveType != null) {
      // Get the hardcoded balance for the selected leave
      final double bal = leaveState.selectedLeaveType!.meta.balance;
      // Strip decimal if it's a whole number (e.g., 2.0 -> "2", 1.5 -> "1.5")
      final formattedBal = bal % 1 == 0 ? bal.toInt().toString() : bal.toString();
      balancePill = _buildPillWidget("Balance: $formattedBal ${bal <= 1 ? 'day' : 'days'}");
    }
    // If it's otherLeave but NO type is selected, balancePill remains null (Hidden).

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.sdp),
          decoration: BoxDecoration(
            color: (isShort ? Colors.green : Colors.orange).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: PhosphorIcon(
            isShort ? PhosphorIcons.clock() : PhosphorIcons.calendarPlus(),
            size: 24.sdp,
            color: isShort ? Colors.green : Colors.orange,
          ),
        ),
        SizedBox(width: 12.sdp),
        Text(
          isShort ? "Short Leave" : "Other Leaves",
          style: AppTextStyle.normal.normal().copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        // Render pill conditionally
        if (balancePill != null) balancePill,
      ],
    );
  }

  Widget _buildPillWidget(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: const Color(0xFFE3FCEF),
        borderRadius: BorderRadius.circular(12.sdp),
      ),
      child: Text(
        text,
        style: AppTextStyle.bold.small(const Color(0xFF006644)),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1.sdp, height: 80.sdp, color: isDark ? Colors.white12 : Colors.grey[300]);
  }
}

class _SheetItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SheetItem({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 4.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: PhosphorIcon(icon, size: 26.sdp, color: color),
            ),
            SizedBox(height: 12.sdp),
            Text(label, textAlign: TextAlign.center, style: AppTextStyle.normal.small()),
          ],
        ),
      ),
    );
  }
}