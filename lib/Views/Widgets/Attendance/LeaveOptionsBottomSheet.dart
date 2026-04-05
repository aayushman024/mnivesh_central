import 'package:flutter/material.dart';
import 'package:mnivesh_central/Utils/DismissKeyboard.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import 'ShortLeaveForm.dart';

class LeaveOptionsSheet extends StatefulWidget {
  const LeaveOptionsSheet({super.key});

  @override
  State<LeaveOptionsSheet> createState() => _LeaveOptionsSheetState();
}

class _LeaveOptionsSheetState extends State<LeaveOptionsSheet> {
  bool _isExpanded = false;
  final int _balanceHours = 8;

  void _openShortLeave() {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
  }

  void _closeShortLeave() {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
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
          // Animate container size changes and cross-fade between views
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _isExpanded
                  ? _buildExpandedView(key: const ValueKey('expanded_view'))
                  : _buildCollapsedMenu(isDark, key: const ValueKey('collapsed_view')),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- COLLAPSED ----------------

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
          onTap: () => Navigator.pop(context),
        ),
        _VerticalDivider(isDark: isDark),
        _SheetItem(
          icon: PhosphorIcons.clock(),
          color: Colors.green,
          label: "Short Leave",
          onTap: _openShortLeave,
        ),
      ],
    );
  }

  // ---------------- EXPANDED ----------------

  Widget _buildExpandedView({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.sdp),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIcons.clock(),
                size: 24.sdp,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12.sdp),
            Text(
              "Short Leave",
              style: AppTextStyle.normal.normal().copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Corporate green pill for balance
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
              decoration: BoxDecoration(
                color: const Color(0xFFE3FCEF),
                borderRadius: BorderRadius.circular(12.sdp),
              ),
              child: Text(
                "Balance: $_balanceHours hrs",
                style: AppTextStyle.bold.small(const Color(0xFF006644)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.sdp),
        ShortLeaveForm(
          balanceHours: _balanceHours,
          onCancel: _closeShortLeave,
          onApply: (date, from, to, reason) {
            // Send payload to backend/bloc here before popping
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ---------------- MICRO-OPTIMIZATIONS ----------------

// Extracted into a StatelessWidget to prevent unnecessary rebuilds
class _VerticalDivider extends StatelessWidget {
  final bool isDark;

  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sdp,
      height: 80.sdp,
      color: isDark ? Colors.white12 : Colors.grey[300],
    );
  }
}

class _SheetItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensures the transparent padding area is still clickable
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 4.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                icon,
                size: 26.sdp,
                color: color,
              ),
            ),
            SizedBox(height: 12.sdp),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.normal.small(),
            ),
          ],
        ),
      ),
    );
  }
}