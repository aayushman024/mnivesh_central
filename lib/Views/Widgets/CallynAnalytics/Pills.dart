import 'package:flutter/material.dart';

import '../../../Utils/Dimensions.dart';

/// A compact coloured badge/pill used throughout the analytics UI.
class AnalyticsPill extends StatelessWidget {
  final String    label;
  final Color     color;
  final double?   fontSize;
  final IconData? icon;

  const AnalyticsPill({
    Key?     key,
    required this.label,
    required this.color,
    this.fontSize,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 6.sdp : 8.sdp,
        vertical:   3.sdp,
      ),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(100),
        border:       Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sdp, color: color),
            SizedBox(width: 4.sdp),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize:      fontSize ?? 10.ssp,
              fontWeight:    FontWeight.w500,
              color:         color,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}