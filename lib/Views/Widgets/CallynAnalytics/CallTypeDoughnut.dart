import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/Dimensions.dart';

// ─── CallTypeDoughnutChart ────────────────────────────────────────────────────

class CallTypeDoughnutChart extends StatelessWidget {
  final List<dynamic> breakdown;

  const CallTypeDoughnutChart({Key? key, required this.breakdown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    int incoming = 0, outgoing = 0, missed = 0;
    for (final item in breakdown) {
      if (item['type'] == 'incoming') incoming = (item['count'] ?? 0) as int;
      if (item['type'] == 'outgoing') outgoing = (item['count'] ?? 0) as int;
      if (item['type'] == 'missed') missed = (item['count'] ?? 0) as int;
    }

    final total = incoming + outgoing + missed;
    if (total == 0) return const SizedBox.shrink();

    const incomingColor = Color(0xFF059669);
    final outgoingColor = cs.primary;
    const missedColor = Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(18.sdp),
      decoration: analyticsCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.sdp,
                height: 36.sdp,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10.sdp),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
                    color: cs.primary.withOpacity(0.85),
                    size: 17.sdp,
                  ),
                ),
              ),
              SizedBox(width: 12.sdp),
              Text(
                'Call Breakdown',
                style: AppTextStyle.bold.custom(
                  15.ssp,
                  cs.onSurface,
                ).copyWith(letterSpacing: -0.2),
              ),
            ],
          ),
          SizedBox(height: 20.sdp),

          Row(
            children: [
              SizedBox(
                height: 120.sdp,
                width: 120.sdp,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 38.sdp,
                          sections: [
                            if (incoming > 0)
                              PieChartSectionData(
                                color: incomingColor.withOpacity(0.82),
                                value: incoming.toDouble(),
                                title: '',
                                radius: 16.sdp,
                              ),
                            if (outgoing > 0)
                              PieChartSectionData(
                                color: outgoingColor.withOpacity(0.82),
                                value: outgoing.toDouble(),
                                title: '',
                                radius: 16.sdp,
                              ),
                            if (missed > 0)
                              PieChartSectionData(
                                color: missedColor.withOpacity(0.82),
                                value: missed.toDouble(),
                                title: '',
                                radius: 16.sdp,
                              ),
                          ],
                        ),
                        swapAnimationDuration:
                        const Duration(milliseconds: 800),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: AppTextStyle.extraBold.custom(
                            20.ssp,
                            cs.onSurface,
                          ).copyWith(height: 1.0),
                        ),
                        SizedBox(height: 2.sdp),
                        Text(
                          'Total',
                          style: AppTextStyle.light.custom(
                            10.ssp,
                            cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24.sdp),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Indicator(
                      color: incomingColor,
                      label: 'Incoming',
                      icon: PhosphorIcons.arrowDownLeft(),
                      value: incoming,
                      total: total,
                    ),
                    SizedBox(height: 14.sdp),
                    _Indicator(
                      color: outgoingColor,
                      label: 'Outgoing',
                      icon: PhosphorIcons.arrowUpRight(),
                      value: outgoing,
                      total: total,
                    ),
                    SizedBox(height: 14.sdp),
                    _Indicator(
                      color: missedColor,
                      label: 'Missed/Rejected',
                      icon: PhosphorIcons.arrowElbowLeft(),
                      value: missed,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── _Indicator ───────────────────────────────────────────────────────────────

class _Indicator extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;
  final PhosphorIconData icon;

  const _Indicator({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = total > 0 ? (value / total * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 8.sdp,
          height: 8.sdp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.80),
          ),
        ),
        SizedBox(width: 8.sdp),
        Expanded(
          child: Row(
            spacing: 5.sdp,
            children: [
              Text(
                label,
                style: AppTextStyle.light.custom(
                  12.ssp,
                  cs.onSurfaceVariant.withOpacity(0.80),
                ),
              ),
              PhosphorIcon(icon, color: color, size: 14.sdp),
            ],
          ),
        ),
        Text(
          value.toString(),
          style: AppTextStyle.extraBold.custom(
            13.ssp,
            cs.onSurface,
          ),
        ),
        SizedBox(width: 4.sdp),
        Text(
          '($pct%)',
          style: AppTextStyle.light.custom(
            10.ssp,
            cs.onSurfaceVariant.withOpacity(0.50),
          ),
        ),
      ],
    );
  }
}