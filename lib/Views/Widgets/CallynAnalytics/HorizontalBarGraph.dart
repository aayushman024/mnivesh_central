import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/CallynDateHelper.dart';
import '../../../Utils/Dimensions.dart';
import 'AnalyticsSkeleton.dart';
import 'Pills.dart';

class GraphColors {
  GraphColors._();

  static const Color topVolume    = Color(0xFFEA820C);
  static const Color workDuration = Color(0xFF2563EB);
  static const Color personalDur  = Color(0xFF059669);
  static const Color topClient    = Color(0xFF0891B2);
  static const Color mostCalled   = Color(0xFF0369A1);
  static const Color avgDuration  = Color(0xFF4F46E5);
  static const Color missedCalls  = Color(0xFFDC2626);
}

// ─── HorizontalBarGraphCard ───────────────────────────────────────────────────

class HorizontalBarGraphCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final PhosphorIconData icon;
  final List<dynamic> items;
  final String titleKey;
  final String valueKey;
  final bool isDuration;
  final String suffix;
  final Color barColor;

  const HorizontalBarGraphCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.titleKey,
    required this.valueKey,
    this.isDuration = false,
    this.suffix = '',
    required this.barColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayItems = items.take(5).toList();

    double maxVal = 0;
    for (final item in displayItems) {
      final v = (item[valueKey] ?? 0) as num;
      if (v > maxVal) maxVal = v.toDouble();
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: EdgeInsets.all(18.sdp),
      decoration: analyticsCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCardHeader(
            context: context,
            icon: icon,
            iconColor: barColor,
            title: title,
            subtitle: subtitle,
          ),
          SizedBox(height: 20.sdp),

          if (displayItems.isEmpty)
            const AnalyticsEmptyState()
          else
            ...displayItems.map((item) {
              final val = (item[valueKey] ?? 0) as num;
              final percent = (val / maxVal).clamp(0.0, 1.0);
              final label = isDuration
                  ? formatDuration(val)
                  : val == 0
                  ? '0 $suffix'
                  : '$val $suffix';

              return _BarRow(
                key: ValueKey(item[titleKey]),
                name: item[titleKey]?.toString() ?? 'Unknown',
                percent: percent,
                label: label,
                barColor: barColor,
              );
            }),
        ],
      ),
    );
  }
}

// ─── _BarRow ──────────────────────────────────────────────────────────────────

class _BarRow extends StatefulWidget {
  final String name;
  final double percent;
  final String label;
  final Color barColor;

  const _BarRow({
    Key? key,
    required this.name,
    required this.percent,
    required this.label,
    required this.barColor,
  }) : super(key: key);

  @override
  State<_BarRow> createState() => _BarRowState();
}

class _BarRowState extends State<_BarRow> {
  double _currentPercent = 0.0;

  @override
  void initState() {
    super.initState();
    // wait for first frame, then push to target percent so AnimatedContainer handles the slide-in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentPercent = widget.percent;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _BarRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _currentPercent = widget.percent;
    }
  }

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
                  widget.name,
                  style: AppTextStyle.normal.custom(
                    13.ssp,
                    cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10.sdp),
              AnalyticsPill(label: widget.label, color: widget.barColor, fontSize: 11.ssp),
            ],
          ),
          SizedBox(height: 8.sdp),
          LayoutBuilder(
            builder: (_, constraints) => ClipRRect(
              borderRadius: BorderRadius.circular(4.sdp),
              child: Stack(
                children: [
                  Container(
                    height: 6.sdp,
                    width: constraints.maxWidth,
                    color: widget.barColor.withOpacity(0.08),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    height: 6.sdp,
                    width: constraints.maxWidth * _currentPercent,
                    decoration: BoxDecoration(
                      // subtle gradient, not too harsh
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.barColor.withOpacity(0.55),
                          widget.barColor.withOpacity(0.95),
                        ],
                      ),
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