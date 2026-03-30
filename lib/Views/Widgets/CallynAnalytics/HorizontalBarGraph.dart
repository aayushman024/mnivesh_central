import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/CallynDateHelper.dart';
import '../../../Utils/Dimensions.dart';
import 'package:flutter/material.dart';

import 'AnalyticsSkeleton.dart';
import 'Pills.dart';

/// Centralised palette for all analytics chart/graph colours.
class GraphColors {
  GraphColors._();

  static const Color topVolume    = Color(0xFF2563EB); // blue-600
  static const Color workDuration = Color(0xFF7C3AED); // violet-700
  static const Color personalDur  = Color(0xFF0891B2); // cyan-600
  static const Color topClient    = Color(0xFF059669); // emerald-600
  static const Color mostCalled   = Color(0xFF0369A1); // sky-700
  static const Color avgDuration  = Color(0xFF4F46E5); // indigo-600
  static const Color missedCalls  = Color(0xFFDC2626); // red-600
}

// ─── HorizontalBarGraphCard ───────────────────────────────────────────────────

/// A card displaying a ranked horizontal bar graph for up to 5 employees.
class HorizontalBarGraphCard extends StatelessWidget {
  final String           title;
  final String           subtitle;
  final PhosphorIconData icon;
  final List<dynamic>    items;
  final String           titleKey;
  final String           valueKey;
  final bool             isDuration;
  final String           suffix;
  final Color            barColor;

  const HorizontalBarGraphCard({
    Key?              key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.titleKey,
    required this.valueKey,
    this.isDuration = false,
    this.suffix     = '',
    required this.barColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final displayItems = items.take(5).toList();

    // Compute max once here; pass pre-calculated percent to each _BarRow
    // so the row widgets don't need to know about sibling values.
    double maxVal = 0;
    for (final item in displayItems) {
      final v = (item[valueKey] ?? 0) as num;
      if (v > maxVal) maxVal = v.toDouble();
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding:    EdgeInsets.all(18.sdp),
      decoration: analyticsCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCardHeader(
            context:   context,
            icon:      icon,
            iconColor: barColor,
            title:     title,
            subtitle:  subtitle,
          ),
          SizedBox(height: 20.sdp),

          if (displayItems.isEmpty)
            const AnalyticsEmptyState()
          else
          // Proper StatelessWidget per row: stable widget identity lets
          // Flutter skip rebuilding unchanged rows when data updates.
            ...displayItems.map((item) {
              final val     = (item[valueKey] ?? 0) as num;
              final percent = (val / maxVal).clamp(0.0, 1.0);
              final label   = isDuration
                  ? formatDuration(val)
                  : val == 0
                  ? '0 $suffix'
                  : '$val $suffix';

              return _BarRow(
                key:      ValueKey(item[titleKey]),
                name:     item[titleKey]?.toString() ?? 'Unknown',
                percent:  percent,
                label:    label,
                barColor: barColor,
              );
            }),
        ],
      ),
    );
  }
}

// ─── _BarRow ──────────────────────────────────────────────────────────────────
//
// Extracted as a StatelessWidget with a ValueKey so that Flutter's element
// reconciler can reuse existing nodes when only specific rows change,
// and the AnimatedContainer can interpolate from its previous state correctly.

class _BarRow extends StatelessWidget {
  final String name;
  final double percent; // 0.0 – 1.0
  final String label;
  final Color  barColor;

  const _BarRow({
    Key?              key,
    required this.name,
    required this.percent,
    required this.label,
    required this.barColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize:   13.ssp,
                    fontWeight: FontWeight.w500,
                    color:      cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10.sdp),
              AnalyticsPill(label: label, color: barColor, fontSize: 11.ssp),
            ],
          ),
          SizedBox(height: 8.sdp),
          LayoutBuilder(
            builder: (_, constraints) => ClipRRect(
              borderRadius: BorderRadius.circular(4.sdp),
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 6.sdp,
                    width:  constraints.maxWidth,
                    color:  barColor.withOpacity(0.08),
                  ),
                  // Fill — AnimatedContainer drives the width animation;
                  // having a stable widget identity (via ValueKey on _BarRow)
                  // means it correctly interpolates from the previous value.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 650),
                    curve:    Curves.easeOutCubic,
                    height:   6.sdp,
                    width:    constraints.maxWidth * percent,
                    decoration: BoxDecoration(
                      color:        barColor.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(4.sdp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}