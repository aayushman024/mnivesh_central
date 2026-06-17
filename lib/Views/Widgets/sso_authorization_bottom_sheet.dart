import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../Managers/AuthManager.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';

class SsoAuthorizationBottomSheet extends StatefulWidget {
  final String appName;
  final VoidCallback onCancel;
  final Function(Map<String, String> data) onConfirm;

  const SsoAuthorizationBottomSheet({
    super.key,
    required this.appName,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<SsoAuthorizationBottomSheet> createState() => _SsoAuthorizationBottomSheetState();
}

class _SsoAuthorizationBottomSheetState extends State<SsoAuthorizationBottomSheet> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _dept = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await AuthManager.hydrate();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('UserName') ?? '';
        _email = prefs.getString('UserEmail') ?? '';
        _phone = prefs.getString('workPhone') ?? '';
        _dept = prefs.getString('user_department') ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium styling colors
    final primaryBlueBg = isDark ? const Color(0xFF0A2540) : const Color(0xFFF0F9FF);
    final primaryBlueBorder = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final primaryBlueText = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);

    final discardRedBg = isDark ? const Color(0xFF2D1616) : const Color(0xFFFEF2F2);
    final discardRedBorder = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final discardRedText = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

    return Container(
      padding: EdgeInsets.fromLTRB(24.sdp, 16.sdp, 24.sdp, 28.sdp),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 48.sdp,
              height: 5.sdp,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.sdp),
              ),
            ),
          ),
          SizedBox(height: 24.sdp),

          // Header with Shield Check icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.sdp),
                decoration: BoxDecoration(
                  color: primaryBlueBg,
                  borderRadius: BorderRadius.circular(16.sdp),
                  border: Border.all(color: primaryBlueBorder.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(
                  PhosphorIconsFill.shieldCheck,
                  color: primaryBlueText,
                  size: 28.sdp,
                ),
              ),
              SizedBox(width: 16.sdp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authorize ${widget.appName}',
                      style: AppTextStyle.extraBold.custom(18.ssp, theme.colorScheme.onSurface),
                    ),
                    SizedBox(height: 4.sdp),
                    Text(
                      'SSO Login Request',
                      style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.sdp),

          // Disclaimer
          Text(
            '${widget.appName} is requesting permission to sign you in using your mNivesh Central credentials. The following profile information will be shared:',
            style: AppTextStyle.normal.custom(13.ssp, theme.colorScheme.onSurface.withOpacity(0.7)).copyWith(height: 1.5),
          ),
          SizedBox(height: 20.sdp),

          // Profile detail card with Skeleton loader
          Skeletonizer(
            enabled: _isLoading,
            child: Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20.sdp),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(isDark ? 0.08 : 0.12),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: PhosphorIconsBold.user,
                    label: 'Name',
                    value: _name.trim().isNotEmpty ? _name : 'N/A',
                    theme: theme,
                  ),
                  Divider(height: 24.sdp, color: theme.colorScheme.outline.withOpacity(0.08)),
                  _buildDetailRow(
                    icon: PhosphorIconsBold.envelope,
                    label: 'Email',
                    value: _email.trim().isNotEmpty ? _email : 'N/A',
                    theme: theme,
                  ),
                  Divider(height: 24.sdp, color: theme.colorScheme.outline.withOpacity(0.08)),
                  _buildDetailRow(
                    icon: PhosphorIconsBold.phone,
                    label: 'Alloted Phone',
                    value: _phone.trim().isNotEmpty ? _phone : 'N/A',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.sdp),

          // Buttons row with custom borders and background colors
          Row(
            children: [
              // Discard / Don't Allow button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: Icon(
                    PhosphorIconsBold.x,
                    size: 16.sdp,
                  ),
                  label: const Text('Don\'t Allow'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: discardRedBg,
                    foregroundColor: discardRedText,
                    side: BorderSide(color: discardRedBorder, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 14.sdp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.sdp),
                    ),
                    textStyle: AppTextStyle.bold.custom(13.ssp, discardRedText),
                  ),
                ),
              ),
              SizedBox(width: 14.sdp),
              // Continue to Login button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          widget.onConfirm({
                            'name': _name,
                            'email': _email,
                            'phone': _phone,
                            'dept': _dept,
                          });
                        },
                  icon: Icon(
                    PhosphorIconsBold.check,
                    size: 16.sdp,
                  ),
                  label: const Text('Continue'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: primaryBlueBg,
                    foregroundColor: primaryBlueText,
                    side: BorderSide(color: primaryBlueBorder, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 14.sdp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.sdp),
                    ),
                    textStyle: AppTextStyle.bold.custom(13.ssp, primaryBlueText),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sdp,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        SizedBox(width: 12.sdp),
        Text(
          label,
          style: AppTextStyle.bold.custom(
            13.ssp,
            theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyle.bold.custom(
            13.ssp,
            theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
