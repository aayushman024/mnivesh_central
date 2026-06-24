import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';

/// Pre-flight permissions consent dialog.
///
/// Shown before both Zoho login and Demo login. Uses Apple-approved
/// "would like to" language that satisfies App Store review guidelines.
///
/// On "Continue": closes the dialog, requests Location + Notification
/// permissions from the OS, then returns `true` to the caller so the
/// login flow can proceed.
///
/// On "Not Now": closes the dialog and returns `false` — no login initiated.
class PermissionsConsentDialog extends StatelessWidget {
  const PermissionsConsentDialog({super.key});

  // ── Public API ────────────────────────────────────────────────────────────

  /// Shows the dialog and, if the user agrees, fires the OS permission prompts.
  ///
  /// Returns `true` when the user tapped "Continue" (regardless of whether
  /// individual permissions were granted), `false` if they tapped "Not Now".
  static Future<bool> show(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PermissionsConsentDialog(),
    );

    if (agreed == true) {
      // Fire actual OS permission prompts after the dialog closes
      await _requestPermissions();
      return true;
    }
    return false;
  }

  /// Requests Location and Notification permissions.
  /// Silently handles any errors — the app works without them.
  static Future<void> _requestPermissions() async {
    try {
      await [
        Permission.locationWhenInUse,
        Permission.notification,
      ].request();
    } catch (_) {
      // Swallow — permissions are optional; app degrades gracefully.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: surfaceColor,
      // Respect keyboard insets so the dialog isn't obscured
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24.sdp,
        vertical: MediaQuery.viewInsetsOf(context).bottom > 0 ? 24.sdp : 40.sdp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.sdp),
        side: BorderSide(color: borderColor),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon & Title ───────────────────────────────────────────────
            Center(
              child: Container(
                padding: EdgeInsets.all(14.sdp),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 16.sdp),
            Center(
              child: Text(
                'Before You Continue',
                textAlign: TextAlign.center,
                style: AppTextStyle.extraBold
                    .large(titleColor)
                    .copyWith(fontSize: 20.ssp),
              ),
            ),
            SizedBox(height: 8.sdp),
            Center(
              child: Text(
                'To give you the best experience, mNivesh Central\nwould like access to a few device features.',
                textAlign: TextAlign.center,
                style:
                    AppTextStyle.normal.small(bodyColor).copyWith(height: 1.5),
              ),
            ),

            SizedBox(height: 24.sdp),

            // ── Permission items ───────────────────────────────────────────
            _PermissionItem(
              emoji: '📍',
              title: 'Location',
              description:
                  'Used to verify attendance and accurately log your field visits.',
              isDark: isDark,
            ),
            SizedBox(height: 12.sdp),
            _PermissionItem(
              emoji: '🔔',
              title: 'Notifications',
              description:
                  'Sends you important updates, announcements, and reminders from your team.',
              isDark: isDark,
            ),

            SizedBox(height: 16.sdp),

            // ── Settings note ──────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(12.sdp),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.sdp),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 8.sdp),
                  Expanded(
                    child: Text(
                      'You can change these permissions at any time in your device Settings.',
                      style: AppTextStyle.normal
                          .small(
                            isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          )
                          .copyWith(fontSize: 11.ssp, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sdp),

            // ── Actions ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.sdp),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.sdp),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: AppTextStyle.normal.normal(bodyColor),
                    ),
                  ),
                ),
                SizedBox(width: 12.sdp),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    // Pop with true — the caller's await receives it, then
                    // _requestPermissions() fires after the dialog is gone.
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.sdp),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.sdp),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyle.bold.normal(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal helper ────────────────────────────────────────────────────────────

class _PermissionItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool isDark;

  const _PermissionItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 12.sdp),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.sdp),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 22.ssp)),
          SizedBox(width: 12.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.bold
                      .normal(titleColor)
                      .copyWith(fontSize: 14.ssp),
                ),
                SizedBox(height: 2.sdp),
                Text(
                  description,
                  style: AppTextStyle.normal
                      .small(bodyColor)
                      .copyWith(height: 1.4, fontSize: 12.ssp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
