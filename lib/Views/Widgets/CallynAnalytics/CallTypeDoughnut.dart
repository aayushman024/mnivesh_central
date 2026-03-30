import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/Dimensions.dart';

// ─── CallTypeDoughnutChart ────────────────────────────────────────────────────

/// Pie/doughnut chart breaking down calls into Incoming / Outgoing / Missed.
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
      if (item['type'] == 'missed')   missed   = (item['count'] ?? 0) as int;
    }

    final total = incoming + outgoing + missed;
    if (total == 0) return const SizedBox.shrink();

    const incomingColor = Color(0xFF059669);
    final outgoingColor = cs.primary;
    const missedColor   = Color(0xFFD97706);

    return Container(
      padding:    EdgeInsets.all(18.sdp),
      decoration: analyticsCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width:  36.sdp,
                height: 36.sdp,
                decoration: BoxDecoration(
                  color:        cs.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10.sdp),
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
                    color: cs.primary.withOpacity(0.85),
                    size:  17.sdp,
                  ),
                ),
              ),
              SizedBox(width: 12.sdp),
              Text(
                'Call Breakdown',
                style: TextStyle(
                  fontSize:      15.ssp,
                  fontWeight:    FontWeight.w700,
                  color:         cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.sdp),

          // ── Chart + legend ──────────────────────────────────────────────────
          Row(
            children: [
              SizedBox(
                height: 120.sdp,
                width:  120.sdp,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // RepaintBoundary: PieChart has a complex custom painter.
                    // Wrapping it means scroll events and unrelated widget
                    // rebuilds above do NOT trigger a chart repaint.
                    RepaintBoundary(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace:     3,
                          centerSpaceRadius: 38.sdp,
                          sections: [
                            if (incoming > 0)
                              PieChartSectionData(
                                color:  incomingColor.withOpacity(0.82),
                                value:  incoming.toDouble(),
                                title:  '',
                                radius: 16.sdp,
                              ),
                            if (outgoing > 0)
                              PieChartSectionData(
                                color:  outgoingColor.withOpacity(0.82),
                                value:  outgoing.toDouble(),
                                title:  '',
                                radius: 16.sdp,
                              ),
                            if (missed > 0)
                              PieChartSectionData(
                                color:  missedColor.withOpacity(0.82),
                                value:  missed.toDouble(),
                                title:  '',
                                radius: 16.sdp,
                              ),
                          ],
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 800),
                        swapAnimationCurve:    Curves.easeInOutCubic,
                      ),
                    ),
                    // Centre label sits outside the RepaintBoundary so it can
                    // update without invalidating the chart's paint layer.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: TextStyle(
                            fontSize:   20.ssp,
                            fontWeight: FontWeight.w800,
                            color:      cs.onSurface,
                            height:     1.0,
                          ),
                        ),
                        SizedBox(height: 2.sdp),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize:   10.ssp,
                            fontWeight: FontWeight.w400,
                            color:      cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24.sdp),

              // ── Legend ──────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Indicator(
                      color: incomingColor,
                      label: 'Incoming',
                      value: incoming,
                      total: total,
                    ),
                    SizedBox(height: 14.sdp),
                    _Indicator(
                      color: outgoingColor,
                      label: 'Outgoing',
                      value: outgoing,
                      total: total,
                    ),
                    SizedBox(height: 14.sdp),
                    _Indicator(
                      color: missedColor,
                      label: 'Missed',
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
  final Color  color;
  final String label;
  final int    value;
  final int    total;

  const _Indicator({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final pct = total > 0 ? (value / total * 100).round() : 0;

    return Row(
      children: [
        Container(
          width:  8.sdp,
          height: 8.sdp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.80),
          ),
        ),
        SizedBox(width: 8.sdp),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize:   12.ssp,
              fontWeight: FontWeight.w400,
              color:      cs.onSurfaceVariant.withOpacity(0.80),
            ),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize:   13.ssp,
            fontWeight: FontWeight.w700,
            color:      cs.onSurface,
          ),
        ),
        SizedBox(width: 4.sdp),
        Text(
          '($pct%)',
          style: TextStyle(
            fontSize:   10.ssp,
            fontWeight: FontWeight.w400,
            color:      cs.onSurfaceVariant.withOpacity(0.50),
          ),
        ),
      ],
    );
  }
}