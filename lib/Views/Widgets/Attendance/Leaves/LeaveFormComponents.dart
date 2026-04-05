import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';

/// Centralized styles for Leave Forms
class LeaveFormStyles {
  static Color primaryBlue(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C9AFF) : const Color(0xFF0052CC);

  static Color textAdaptive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF4F5F7) : const Color(0xFF172B4D);

  static Color borderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF344563) : const Color(0xFFDFE1E6);

  static InputDecoration baseDecoration(BuildContext context, String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyle.normal.small(textAdaptive(context).withOpacity(0.6)),
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.sdp),
        borderSide: BorderSide(color: borderSubtle(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.sdp),
        borderSide: BorderSide(color: primaryBlue(context), width: 1.5),
      ),
    );
  }
}

/// Shared Duration Indicator Card
class LeaveDurationIndicator extends StatelessWidget {
  final String duration;
  final IconData icon;

  const LeaveDurationIndicator({
    super.key,
    required this.duration,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = LeaveFormStyles.primaryBlue(context);
    final textAdaptive = LeaveFormStyles.textAdaptive(context);

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
          Icon(icon, color: primaryBlue, size: 20.sdp),
          SizedBox(width: 12.sdp),
          Text(
            "Total Duration:",
            style: AppTextStyle.normal.small(textAdaptive.withOpacity(0.7)),
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
}

/// Shared Action Buttons (Discard / Apply)
class LeaveActionButtons extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback? onApply; // Nullable to handle disabled state

  const LeaveActionButtons({
    super.key,
    required this.onDiscard,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = LeaveFormStyles.primaryBlue(context);
    const redColor = Color(0xFFDE350B);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onDiscard,
            style: OutlinedButton.styleFrom(
              foregroundColor: redColor,
              backgroundColor: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.symmetric(vertical: 16.sdp),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.sdp)),
              side: const BorderSide(color: redColor),
              elevation: 0,
            ),
            child: Text("Discard", style: AppTextStyle.bold.normal(redColor)),
          ),
        ),
        SizedBox(width: 16.sdp),
        Expanded(
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: primaryBlue.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16.sdp),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.sdp)),
            ),
            child: Text("Apply", style: AppTextStyle.bold.normal(Colors.white)),
          ),
        ),
      ],
    );
  }
}

/// Shared Success View with Lottie Animation
class LeaveSuccessView extends StatelessWidget {
  final String message;

  const LeaveSuccessView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final textAdaptive = LeaveFormStyles.textAdaptive(context);

    return Column(
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
          message,
          style: AppTextStyle.bold.normal(textAdaptive),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}