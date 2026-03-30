import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

// small circular button for grid overlays
class AsyncCircleButton extends StatefulWidget {
  final PhosphorIconData icon;
  final ColorScheme colorScheme;
  final bool isFilled;
  final Future Function() onTap;

  const AsyncCircleButton({
    super.key,
    required this.icon,
    required this.colorScheme,
    this.isFilled = true,
    required this.onTap,
  });

  @override
  State<AsyncCircleButton> createState() => _AsyncCircleButtonState();
}

class _AsyncCircleButtonState extends State<AsyncCircleButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isFilled
        ? widget.colorScheme.primary
        : widget.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final iconColor = widget.isFilled
        ? widget.colorScheme.onPrimary
        : widget.colorScheme.primary;

    return GestureDetector(
      onTap: () async {
        if (_isLoading) return;
        if (mounted) setState(() => _isLoading = true);
        await widget.onTap();
        if (mounted) setState(() => _isLoading = false);
      },
      child: Container(
        padding: EdgeInsets.all(10.sdp),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: _isLoading
            ? SizedBox(
          width: 16.sdp,
          height: 16.sdp,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(iconColor),
          ),
        )
            : PhosphorIcon(widget.icon, color: iconColor, size: 16.sdp),
      ),
    );
  }
}

// full width/pill button for expanded view
class AsyncExpandedButton extends StatefulWidget {
  final PhosphorIconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isPrimary;
  final Future Function() onTap;

  const AsyncExpandedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<AsyncExpandedButton> createState() => _AsyncExpandedButtonState();
}

class _AsyncExpandedButtonState extends State<AsyncExpandedButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? widget.colorScheme.primary
        : Colors.white.withOpacity(0.15);
    final fgColor = widget.isPrimary
        ? widget.colorScheme.onPrimary
        : Colors.white;

    return ElevatedButton.icon(
      onPressed: () async {
        if (_isLoading) return;
        if (mounted) setState(() => _isLoading = true);
        await widget.onTap();
        if (mounted) setState(() => _isLoading = false);
      },
      icon: _isLoading
          ? SizedBox(
        width: 18.sdp,
        height: 18.sdp,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(fgColor),
        ),
      )
          : PhosphorIcon(widget.icon, size: 18.sdp, color: fgColor),
      label: Text(
        widget.label,
        style: AppTextStyle.extraBold
            .normal(fgColor)
            .copyWith(fontSize: 14.ssp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: widget.isPrimary ? 8 : 0,
        shadowColor: widget.colorScheme.primary.withOpacity(0.5),
        padding: EdgeInsets.symmetric(horizontal: 24.sdp, vertical: 14.sdp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.sdp),
          side: BorderSide(
            color: widget.isPrimary ? Colors.transparent : Colors.white24,
            width: 1,
          ),
        ),
      ),
    );
  }
}