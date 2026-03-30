import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Utils/Dimensions.dart';

// ─── Card decoration ──────────────────────────────────────────────────────────

/// Standard rounded card [BoxDecoration] used across all analytics cards.
BoxDecoration analyticsCardDecoration(ColorScheme cs) => BoxDecoration(
  color:        cs.surface,
  borderRadius: BorderRadius.circular(20.sdp),
  border: Border.all(
    color: cs.outlineVariant.withOpacity(0.10),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color:      cs.shadow.withOpacity(0.04),
      blurRadius: 16.sdp,
      offset:     Offset(0, 5.sdp),
    ),
  ],
);

// ─── Card header ──────────────────────────────────────────────────────────────

/// Standard icon + title/subtitle header used at the top of every card.
Widget buildCardHeader({
  required BuildContext      context,
  required PhosphorIconData  icon,
  required Color             iconColor,
  required String            title,
  required String            subtitle,
}) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width:  36.sdp,
        height: 36.sdp,
        decoration: BoxDecoration(
          color:        iconColor.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10.sdp),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            color: iconColor.withOpacity(0.85),
            size:  17.sdp,
          ),
        ),
      ),
      SizedBox(width: 12.sdp),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize:      15.ssp,
              fontWeight:    FontWeight.w700,
              color:         cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 1.sdp),
          Text(
            subtitle,
            style: TextStyle(
              fontSize:   11.ssp,
              fontWeight: FontWeight.w400,
              color:      cs.onSurfaceVariant.withOpacity(0.60),
            ),
          ),
        ],
      ),
    ],
  );
}