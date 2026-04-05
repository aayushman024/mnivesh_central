import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import 'LeaveOptionsBottomSheet.dart';

class LeaveFloatingActionButton extends StatefulWidget {
  const LeaveFloatingActionButton({super.key});

  @override
  State<LeaveFloatingActionButton> createState() => _LeaveFloatingActionButtonState();
}

class _LeaveFloatingActionButtonState extends State<LeaveFloatingActionButton> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final bgColor = isDark ? colorScheme.surfaceContainerHigh : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(color: colorScheme.primary, width: 1.sdp),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: colorScheme.primary.withAlpha(40),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(4, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              spreadRadius: 4,
              offset: const Offset(4, 6),
            ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          // Fire off bottom sheet. Drag handle gives us the slide-to-dismiss behavior OOTB.
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => const LeaveOptionsSheet(),
          );
        },
        backgroundColor: bgColor,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        tooltip: 'Apply Leaves',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.sdp),
        ),
        icon: PhosphorIcon(
          PhosphorIcons.listPlus(),
          size: 20.sdp,
          color: colorScheme.primary,
        ),
        label: Text(
          "Apply Leave",
          style: AppTextStyle.normal.custom(14.ssp).copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
