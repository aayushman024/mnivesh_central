import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class LeaveOptionsSheet extends StatelessWidget {
  const LeaveOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24.sdp,
        left: 16.sdp,
        right: 16.sdp,
        top: 8.sdp,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SheetItem(
            icon: PhosphorIcons.files(),
            color: Colors.deepPurpleAccent,
            label: "View Leaves",
            onTap: () {
              Navigator.pop(context);
              // TODO: wire up view leaves
            },
          ),
          Container(
            width: 1.sdp,
            color: isDark ? Colors.white12 : Colors.grey[300],
            height: 80.sdp,
          ),
          _SheetItem(
            icon: PhosphorIcons.calendarPlus(),
            color: Colors.orange,
            label: "Other Leaves",
            onTap: () {
              Navigator.pop(context);
              // TODO: wire up other leaves
            },
          ),
          Container(
            width: 1.sdp,
            color: isDark ? Colors.white12 : Colors.grey[300],
            height: 80.sdp,
          ),
          _SheetItem(
            icon: PhosphorIcons.clock(),
            color: Colors.green,
            label: "Short Leave",
            onTap: () {
              Navigator.pop(context);
              // TODO: wire up short leave navigation
            },
          ),
        ],
      ),
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
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sdp),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 4.sdp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.sdp),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
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
                style: AppTextStyle.normal.small()),
            ],
          ),
        ),
      ),
    );
  }
}