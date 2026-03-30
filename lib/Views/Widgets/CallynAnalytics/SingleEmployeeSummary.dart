import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Models/callyn_analytics_model.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/CallynDateHelper.dart';
import '../../../Utils/Dimensions.dart';
import 'HorizontalBarGraph.dart';

// ─── SingleEmployeeSummary ────────────────────────────────────────────────────

class SingleEmployeeSummary extends StatelessWidget {
  final CallLogAnalyticsModel data;

  const SingleEmployeeSummary({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workDur = data.mostWorkCallDuration.isNotEmpty
        ? (data.mostWorkCallDuration.first['totalWorkDuration'] ?? 0) as num
        : 0;
    final persDur = data.mostPersonalCallDuration.isNotEmpty
        ? (data.mostPersonalCallDuration.first['totalPersonalDuration'] ?? 0) as num
        : 0;
    final avgDur = data.avgCallDurationPerEmployee.isNotEmpty
        ? (data.avgCallDurationPerEmployee.first['avgDuration'] ?? 0) as num
        : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Work Dur.',
                value: formatDuration(workDur),
                icon: PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
                color: GraphColors.workDuration,
              ),
            ),
            SizedBox(width: 12.sdp),
            Expanded(
              child: _StatCard(
                title: 'Pers. Dur.',
                value: formatDuration(persDur),
                icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                color: GraphColors.personalDur,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sdp),
        _StatCard(
          title: 'Avg Call Duration',
          value: formatDuration(avgDur),
          icon: PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
          color: GraphColors.avgDuration,
          isFullWidth: true,
        ),
      ],
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final PhosphorIconData icon;
  final Color color;
  final bool isFullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.sdp),
      decoration: analyticsCardDecoration(cs),
      child: Row(
        mainAxisAlignment: isFullWidth
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.sdp),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.sdp),
            ),
            child: PhosphorIcon(icon, color: color, size: 20.sdp),
          ),
          if (isFullWidth) SizedBox(width: 16.sdp),
          Column(
            crossAxisAlignment: isFullWidth
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: AppTextStyle.light.custom(
                  11.ssp,
                  cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.sdp),
              Text(
                value,
                style: AppTextStyle.bold.custom(
                  15.ssp,
                  cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}