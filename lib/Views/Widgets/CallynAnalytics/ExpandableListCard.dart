import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/CallynCardHelper.dart';
import '../../../Utils/CallynDateHelper.dart';
import '../../../Utils/Dimensions.dart';
import 'AnalyticsSkeleton.dart';
import 'Pills.dart';

// ─── ExpandableListCard ───────────────────────────────────────────────────────
class ExpandableListCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final PhosphorIconData icon;
  final List<dynamic> items;
  final String titleKey;
  final String valueKey;
  final String? subtitleKey;
  final String subtitleSuffix;
  final bool subtitleAsPill;
  final bool isDuration;
  final String suffix;
  final Color? iconColor;

  const ExpandableListCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.titleKey,
    required this.valueKey,
    this.subtitleKey,
    this.subtitleSuffix = '',
    this.subtitleAsPill = false,
    this.isDuration = false,
    this.suffix = '',
    this.iconColor,
  }) : super(key: key);

  @override
  State<ExpandableListCard> createState() => _ExpandableListCardState();
}

class _ExpandableListCardState extends State<ExpandableListCard> {
  static const int _kCollapsed = 3;
  bool _isExpanded = false;

  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = widget.iconColor ?? cs.primary;
    final hasMore = widget.items.length > _kCollapsed;
    final display = _isExpanded
        ? widget.items
        : widget.items.take(_kCollapsed).toList();

    return Container(
      decoration: analyticsCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(18.sdp),
            child: buildCardHeader(
              context: context,
              icon: widget.icon,
              iconColor: accent,
              title: widget.title,
              subtitle: widget.subtitle,
            ),
          ),

          if (widget.items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 24.sdp),
              child: const Center(child: AnalyticsEmptyState()),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  ...display.asMap().entries.map(
                        (e) => _ListItem(
                      key: ValueKey(e.key),
                      item: e.value,
                      index: e.key,
                      titleKey: widget.titleKey,
                      valueKey: widget.valueKey,
                      subtitleKey: widget.subtitleKey,
                      subtitleSuffix: widget.subtitleSuffix,
                      subtitleAsPill: widget.subtitleAsPill,
                      isDuration: widget.isDuration,
                      suffix: widget.suffix,
                      accent: accent,
                    ),
                  ),
                  if (hasMore)
                    _ExpandToggle(
                      isExpanded: _isExpanded,
                      itemCount: widget.items.length,
                      accent: accent,
                      onTap: _toggleExpand,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── _ListItem ────────────────────────────────────────────────────────────────

class _ListItem extends StatelessWidget {
  final dynamic item;
  final int index;
  final String titleKey;
  final String valueKey;
  final String? subtitleKey;
  final String subtitleSuffix;
  final bool subtitleAsPill;
  final bool isDuration;
  final String suffix;
  final Color accent;

  const _ListItem({
    Key? key,
    required this.item,
    required this.index,
    required this.titleKey,
    required this.valueKey,
    this.subtitleKey,
    this.subtitleSuffix = '',
    this.subtitleAsPill = false,
    this.isDuration = false,
    this.suffix = '',
    required this.accent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final val = item[valueKey] ?? 0;
    final displayValue = isDuration
        ? formatDuration(val)
        : '$val $suffix';
    final title = item[titleKey]?.toString() ?? 'Unknown';

    String? sub;
    if (subtitleKey != null && item[subtitleKey] != null) {
      sub = subtitleAsPill
          ? item[subtitleKey].toString()
          : '${item[subtitleKey]} $subtitleSuffix'.trim();
    }

    return Padding(
      padding: EdgeInsets.only(left: 18.sdp, right: 18.sdp, bottom: 14.sdp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.sdp,
            child: Text(
              '${index + 1}.',
              style: AppTextStyle.normal.custom(
                12.ssp,
                cs.onSurfaceVariant.withOpacity(0.50),
              ),
            ),
          ),
          SizedBox(width: 8.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  SizedBox(height: 4.sdp),
                  subtitleAsPill
                      ? AnalyticsPill(label: sub, color: accent)
                      : Text(
                    sub,
                    style: AppTextStyle.light.custom(
                      11.ssp,
                      cs.onSurfaceVariant.withOpacity(0.60),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.sdp),
          AnalyticsPill(
            label: displayValue,
            color: accent,
            fontSize: 11.ssp,
          ),
        ],
      ),
    );
  }
}

// ─── _ExpandToggle ────────────────────────────────────────────────────────────

class _ExpandToggle extends StatelessWidget {
  final bool isExpanded;
  final int itemCount;
  final Color accent;
  final VoidCallback onTap;

  const _ExpandToggle({
    required this.isExpanded,
    required this.itemCount,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.sdp),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.10)),
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.sdp),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpanded ? 'Show Less' : 'View All ($itemCount)',
              style: AppTextStyle.bold.custom(
                12.ssp,
                accent.withOpacity(0.85),
              ),
            ),
            SizedBox(width: 4.sdp),
            PhosphorIcon(
              isExpanded
                  ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                  : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              color: accent.withOpacity(0.85),
              size: 12.sdp,
            ),
          ],
        ),
      ),
    );
  }
}