import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/callynAnalytics_viewModel.dart';
import '../../Models/callyn_analytics_model.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
class _GraphColors {
  static const Color topVolume    = Color(0xFF2563EB); // blue-600
  static const Color workDuration = Color(0xFF7C3AED); // violet-700
  static const Color personalDur  = Color(0xFF0891B2); // cyan-600
  static const Color topClient    = Color(0xFF059669); // emerald-600
  static const Color mostCalled   = Color(0xFF0369A1); // sky-700
  static const Color avgDuration  = Color(0xFF4F46E5); // indigo-600
  static const Color missedCalls  = Color(0xFFDC2626); // red-600
}

// ─── Date-range helpers ───────────────────────────────────────────────────────
String _filterDateHint(AnalyticsFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case AnalyticsFilter.today:
      return _fmt(now);
    case AnalyticsFilter.yesterday:
      return _fmt(now.subtract(const Duration(days: 1)));
    case AnalyticsFilter.thisWeek:
      final start = now.subtract(Duration(days: now.weekday - 1));
      return '${_fmtShort(start)} – ${_fmtShort(now)}';
    case AnalyticsFilter.lastWeek:
      final startOfThis = now.subtract(Duration(days: now.weekday - 1));
      final endLast     = startOfThis.subtract(const Duration(days: 1));
      final startLast   = startOfThis.subtract(const Duration(days: 7));
      return '${_fmtShort(startLast)} – ${_fmtShort(endLast)}';
    case AnalyticsFilter.currentMonth:
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ];
      return months[now.month - 1];
    case AnalyticsFilter.allTime:
      return '';
  }
}

String _fmt(DateTime d) => '${d.day} ${_monthAbbr(d.month)} ${d.year}';
String _fmtShort(DateTime d) => '${d.day} ${_monthAbbr(d.month)}';
String _monthAbbr(int m) {
  const a = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return a[m - 1];
}

String _formatDuration(num s) {
  if (s == 0) return '0s';
  int t   = s.round();
  int h   = t ~/ 3600;
  int m   = (t % 3600) ~/ 60;
  int sec = t % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${sec}s';
  return '${sec}s';
}

// ─── Pill widget ──────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.color,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 6.sdp : 8.sdp,
        vertical: 3.sdp,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
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
              fontSize:   fontSize ?? 10.ssp,
              fontWeight: FontWeight.w500,
              color:      color,
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

// ─── Screen ───────────────────────────────────────────────────────────────────
class CallynAnalyticsScreen extends StatelessWidget {
  const CallynAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return ChangeNotifierProvider(
      create: (_) => CallLogAnalyticsViewModel(),
      child: const _CallLogAnalyticsView(),
    );
  }
}

class _CallLogAnalyticsView extends StatelessWidget {
  const _CallLogAnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isLoading     = context.select((CallLogAnalyticsViewModel v) => v.isLoading);
    final errorMessage  = context.select((CallLogAnalyticsViewModel v) => v.errorMessage);
    final currentFilter = context.select((CallLogAnalyticsViewModel v) => v.selectedFilter);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: theme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        backgroundColor:  Colors.transparent,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: PhosphorIcon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
        ),
        title: Text(
          'Analytics',
          style: AppTextStyle.bold.large(colorScheme.onSurface).copyWith(
            fontSize:      20.ssp,
            fontWeight:    FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 8.sdp),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
                boxShadow: [
                  BoxShadow(
                    color:      colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 24.sdp,
                    offset:     Offset(0, -6.sdp),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
                child: Column(
                  children: [
                    SizedBox(height: 12.sdp),
                    Center(
                      child: Container(
                        width: 36.sdp,
                        height: 4.sdp,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(2.sdp),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.sdp),
                    const _EmployeeFilterDropdown(),
                    SizedBox(height: 12.sdp),

                    const _FilterTabs(),
                    SizedBox(height: 4.sdp),
                    Expanded(
                      child: _buildMainContent(
                        context, isLoading, errorMessage, currentFilter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context,
      bool isLoading,
      String? errorMessage,
      AnalyticsFilter currentFilter,
      ) {
    if (isLoading) return const _AnalyticsSkeletonLoader();

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
              size:  48.sdp,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.sdp),
            Text(
              errorMessage,
              style: AppTextStyle.normal
                  .normal(Theme.of(context).colorScheme.error)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20.sdp),
            FilledButton.icon(
              onPressed: context.read<CallLogAnalyticsViewModel>().fetchData,
              icon:      const Icon(Icons.refresh_rounded, size: 16),
              label:     const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = context.select((CallLogAnalyticsViewModel v) => v.analyticsData);
    if (data == null) return const SizedBox.shrink();

    final isSingleEmployee = context.select((CallLogAnalyticsViewModel v) => v.searchName != null);

    return RefreshIndicator(
      onRefresh: context.read<CallLogAnalyticsViewModel>().fetchData,
      color:     Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.only(left: 16.sdp, right: 16.sdp, top: 16.sdp, bottom: 80.sdp),
        children: isSingleEmployee
            ? _buildSingleEmployeeView(data)
            : _buildAllEmployeesView(data),
      ),
    );
  }

  List<Widget> _buildSingleEmployeeView(CallLogAnalyticsModel data) {
    return [
      _SingleEmployeeSummary(data: data),
      SizedBox(height: 16.sdp),
      _CallTypeDoughnutChart(breakdown: data.callTypeBreakdown),
      SizedBox(height: 16.sdp),
      SizedBox(height: 16.sdp),
      _ExpandableListCard(
        title:          'Most Called Contacts',
        subtitle:       'By Call Frequency',
        icon:           PhosphorIcons.buildings(PhosphorIconsStyle.fill),
        items:          data.mostFrequentlyCalledClients,
        titleKey:       'client',
        subtitleKey:    'familyHead',
        subtitleAsPill: true,
        valueKey:       'callCount',
        suffix:         'calls',
        iconColor:      _GraphColors.mostCalled,
      ),
      SizedBox(height: 16.sdp),
      _ExpandableListCard(
        title:          'Longest Contact Calls',
        subtitle:       'By Total Duration',
        icon:           PhosphorIcons.clock(PhosphorIconsStyle.fill),
        items:          data.mostCalledClientsByDuration,
        titleKey:       'client',
        subtitleKey:    'familyHead',
        subtitleAsPill: true,
        valueKey:       'totalDuration',
        isDuration:     true,
        iconColor:      _GraphColors.workDuration,
      ),
    ];
  }

  List<Widget> _buildAllEmployeesView(CallLogAnalyticsModel data) {
    return [
      _CallTypeDoughnutChart(breakdown: data.callTypeBreakdown),
      SizedBox(height: 16.sdp),
      SizedBox(height: 16.sdp),

      _HorizontalBarGraphCard(
        title:    'Top Call Volume',
        subtitle: 'By Employee',
        icon:     PhosphorIcons.phoneCall(PhosphorIconsStyle.fill),
        items:    data.mostCallsMade,
        titleKey: 'employee',
        valueKey: 'totalCalls',
        suffix:   'calls',
        barColor: _GraphColors.topVolume,
      ),
      SizedBox(height: 16.sdp),

      _HorizontalBarGraphCard(
        title:      'Longest Work Calls',
        subtitle:   'Total Duration/Employee',
        icon:       PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
        items:      data.mostWorkCallDuration,
        titleKey:   'employee',
        valueKey:   'totalWorkDuration',
        isDuration: true,
        barColor:   _GraphColors.workDuration,
      ),
      SizedBox(height: 16.sdp),

      _HorizontalBarGraphCard(
        title:      'Longest Personal Calls',
        subtitle:   'Total Duration/Employee',
        icon:       PhosphorIcons.user(PhosphorIconsStyle.fill),
        items:      data.mostPersonalCallDuration,
        titleKey:   'employee',
        valueKey:   'totalPersonalDuration',
        isDuration: true,
        barColor:   _GraphColors.personalDur,
      ),
      SizedBox(height: 16.sdp),

      _HorizontalBarGraphCard(
        title:      'Missed / Rejected Calls',
        subtitle:   'By Employee',
        icon:       PhosphorIcons.phoneDisconnect(PhosphorIconsStyle.fill),
        items:      data.missedOrRejectedPerEmployee,
        titleKey:   'employee',
        valueKey:   'missedOrRejected',
        suffix:     'calls',
        barColor:   _GraphColors.missedCalls,
      ),
      SizedBox(height: 16.sdp),

      _ExpandableListCard(
        title:          'Avg Call Duration',
        subtitle:       'Per Employee',
        icon:           PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
        items:          data.avgCallDurationPerEmployee,
        titleKey:       'employee',
        subtitleKey:    'totalCalls',
        subtitleSuffix: 'total calls',
        valueKey:       'avgDuration',
        isDuration:     true,
        iconColor:      _GraphColors.avgDuration,
      ),
      SizedBox(height: 16.sdp),

      _ExpandableListCard(
        title:          'Most Called Contacts',
        subtitle:       'By Call Frequency',
        icon:           PhosphorIcons.buildings(PhosphorIconsStyle.fill),
        items:          data.mostFrequentlyCalledClients,
        titleKey:       'client',
        subtitleKey:    'familyHead',
        subtitleAsPill: true,
        valueKey:       'callCount',
        suffix:         'calls',
        iconColor:      _GraphColors.mostCalled,
      ),
      SizedBox(height: 16.sdp),

      _ExpandableListCard(
        title:          'Longest Contact Calls',
        subtitle:       'By Total Duration',
        icon:           PhosphorIcons.clock(PhosphorIconsStyle.fill),
        items:          data.mostCalledClientsByDuration,
        titleKey:       'client',
        subtitleKey:    'familyHead',
        subtitleAsPill: true,
        valueKey:       'totalDuration',
        isDuration:     true,
        iconColor:      _GraphColors.workDuration,
      ),
    ];
  }
}

// ─── Single Employee Summary Stats ────────────────────────────────────────────
class _SingleEmployeeSummary extends StatelessWidget {
  final CallLogAnalyticsModel data;
  const _SingleEmployeeSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    num workDur    = data.mostWorkCallDuration.isNotEmpty ? data.mostWorkCallDuration[0]['totalWorkDuration'] ?? 0 : 0;
    num persDur    = data.mostPersonalCallDuration.isNotEmpty ? data.mostPersonalCallDuration[0]['totalPersonalDuration'] ?? 0 : 0;
    num avgDur     = data.avgCallDurationPerEmployee.isNotEmpty ? data.avgCallDurationPerEmployee[0]['avgDuration'] ?? 0 : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Work Dur.', value: _formatDuration(workDur), icon: PhosphorIcons.briefcase(PhosphorIconsStyle.fill), color: _GraphColors.workDuration)),
            SizedBox(width: 12.sdp),
            Expanded(child: _StatCard(title: 'Pers. Dur.', value: _formatDuration(persDur), icon: PhosphorIcons.user(PhosphorIconsStyle.fill), color: _GraphColors.personalDur)),
          ],
        ),
        SizedBox(height: 12.sdp),
        _StatCard(title: 'Avg Call Duration', value: _formatDuration(avgDur), icon: PhosphorIcons.trendUp(PhosphorIconsStyle.fill), color: _GraphColors.avgDuration, isFullWidth: true),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final PhosphorIconData icon;
  final Color color;
  final bool isFullWidth;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.sdp),
      decoration: _cardDecoration(cs),
      child: Row(
        mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.sdp),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.sdp)),
            child: PhosphorIcon(icon, color: color, size: 20.sdp),
          ),
          if (isFullWidth) SizedBox(width: 16.sdp),
          Column(
            crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(title, style: TextStyle(fontSize: 11.ssp, color: cs.onSurfaceVariant)),
              SizedBox(height: 4.sdp),
              Text(value, style: TextStyle(fontSize: 15.ssp, fontWeight: FontWeight.bold, color: cs.onSurface)),
            ],
          )
        ],
      ),
    );
  }
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────
class _FilterTabs extends StatefulWidget {
  const _FilterTabs({Key? key}) : super(key: key);

  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  DateTime?      _customDate;
  DateTimeRange? _customRange;
  String? _customActive;

  Future<void> _pickDate(CallLogAnalyticsViewModel vm) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _customDate ?? now,
      firstDate:   DateTime(now.year - 5),
      lastDate:    now,
    );
    if (picked != null && mounted) {
      setState(() {
        _customDate   = picked;
        _customRange  = null;
        _customActive = 'date';
      });
      vm.setCustomDate(picked);
    }
  }

  Future<void> _pickRange(CallLogAnalyticsViewModel vm) async {
    final now    = DateTime.now();
    final picked = await showDateRangePicker(
      context:   context,
      firstDate: DateTime(now.year - 5),
      lastDate:  now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end:   now,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange  = picked;
        _customDate   = null;
        _customActive = 'range';
      });
      vm.setCustomDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm          = context.watch<CallLogAnalyticsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 54.sdp,
      child: ListView(
        padding:         EdgeInsets.symmetric(horizontal: 16.sdp),
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        children: [
          ...AnalyticsFilter.values.map((filter) {
            final isSelected =
                vm.selectedFilter == filter && _customActive == null;
            final hint = _filterDateHint(filter);

            return Padding(
              padding: EdgeInsets.only(right: 8.sdp),
              child: GestureDetector(
                onTap: () {
                  setState(() => _customActive = null);
                  vm.setFilter(filter);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve:    Curves.easeOutCubic,
                  padding:  EdgeInsets.symmetric(
                      horizontal: 14.sdp, vertical: 6.sdp),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.88)
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12.sdp),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.80)
                          : colorScheme.outlineVariant.withOpacity(0.20),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color:      colorScheme.primary.withOpacity(0.16),
                        blurRadius: 8.sdp,
                        offset:     Offset(0, 3.sdp),
                      ),
                    ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.filterLabels[filter]!,
                        style: TextStyle(
                          fontSize:      13.ssp,
                          fontWeight:    FontWeight.w600,
                          color:         isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (hint.isNotEmpty) ...[
                        SizedBox(height: 2.sdp),
                        Text(
                          hint,
                          style: TextStyle(
                            fontSize:   10.ssp,
                            fontWeight: FontWeight.w400,
                            color:      isSelected
                                ? colorScheme.onPrimary.withOpacity(0.68)
                                : colorScheme.onSurfaceVariant.withOpacity(0.58),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          _DatePickerChip(
            icon:     PhosphorIcons.calendar(PhosphorIconsStyle.regular),
            label:    _customActive == 'date' && _customDate != null
                ? _fmt(_customDate!)
                : 'Select Date',
            isActive: _customActive == 'date',
            cs:       colorScheme,
            onTap:    () => _pickDate(vm),
          ),
          SizedBox(width: 8.sdp),

          _DatePickerChip(
            icon:     PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
            label:    _customActive == 'range' && _customRange != null
                ? '${_fmtShort(_customRange!.start)} – ${_fmtShort(_customRange!.end)}'
                : 'Select Range',
            isActive: _customActive == 'range',
            cs:       colorScheme,
            onTap:    () => _pickRange(vm),
          ),
        ],
      ),
    );
  }
}

class _DatePickerChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final bool isActive;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _DatePickerChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeOutCubic,
        padding:  EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 6.sdp),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withOpacity(0.88)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(
            color: isActive
                ? cs.primary.withOpacity(0.80)
                : cs.outlineVariant.withOpacity(0.20),
            width: 1,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color:      cs.primary.withOpacity(0.16),
              blurRadius: 8.sdp,
              offset:     Offset(0, 3.sdp),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size:  13.sdp,
              color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            SizedBox(width: 6.sdp),
            Text(
              label,
              style: TextStyle(
                fontSize:      13.ssp,
                fontWeight:    FontWeight.w600,
                color:         isActive ? cs.onPrimary : cs.onSurface,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card decoration ──────────────────────────────────────────────────────────
BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
  color:        cs.surface,
  borderRadius: BorderRadius.circular(20.sdp),
  border:       Border.all(color: cs.outlineVariant.withOpacity(0.10), width: 1),
  boxShadow: [
    BoxShadow(
      color:      cs.shadow.withOpacity(0.04),
      blurRadius: 16.sdp,
      offset:     Offset(0, 5.sdp),
    ),
  ],
);

Widget _cardHeader({
  required BuildContext context,
  required PhosphorIconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
}) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 36.sdp, height: 36.sdp,
        decoration: BoxDecoration(
          color:        iconColor.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10.sdp),
        ),
        child: Center(
          child: PhosphorIcon(icon, color: iconColor.withOpacity(0.85), size: 17.sdp),
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

// ─── Horizontal Bar Graph ─────────────────────────────────────────────────────
class _HorizontalBarGraphCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final PhosphorIconData icon;
  final List<dynamic> items;
  final String titleKey;
  final String valueKey;
  final bool isDuration;
  final String suffix;
  final Color barColor;

  const _HorizontalBarGraphCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.titleKey,
    required this.valueKey,
    this.isDuration = false,
    this.suffix = '',
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final displayItems = items.take(5).toList();
    double maxVal      = 0;
    for (var item in displayItems) {
      final val = (item[valueKey] ?? 0) as num;
      if (val > maxVal) maxVal = val.toDouble();
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding:    EdgeInsets.all(18.sdp),
      decoration: _cardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            context:   context,
            icon:      icon,
            iconColor: barColor,
            title:     title,
            subtitle:  subtitle,
          ),
          SizedBox(height: 20.sdp),
          if (displayItems.isEmpty)
            _EmptyState()
          else
            ...displayItems.map((item) {
              final val          = (item[valueKey] ?? 0) as num;
              final percent      = (val / maxVal).clamp(0.0, 1.0);
              final displayValue = isDuration
                  ? _formatDuration(val)
                  : val == 0
                  ? '0 $suffix'
                  : '$val $suffix';
              final name = item[titleKey]?.toString() ?? 'Unknown';

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
                        _Pill(
                          label: displayValue,
                          color: barColor,
                          fontSize: 11.ssp,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.sdp),
                    LayoutBuilder(builder: (ctx, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4.sdp),
                        child: Stack(
                          children: [
                            Container(
                              height: 6.sdp,
                              width:  constraints.maxWidth,
                              color:  barColor.withOpacity(0.08),
                            ),
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
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// ─── Expandable List ──────────────────────────────────────────────────────────
class _ExpandableListCard extends StatefulWidget {
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

  const _ExpandableListCard({
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
  });

  @override
  State<_ExpandableListCard> createState() => _ExpandableListCardState();
}

class _ExpandableListCardState extends State<_ExpandableListCard> {
  bool _isExpanded = false;
  static const int _collapsed = 3;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final accent  = widget.iconColor ?? cs.primary;
    final hasMore = widget.items.length > _collapsed;
    final display = _isExpanded ? widget.items : widget.items.take(_collapsed).toList();

    return Container(
      decoration: _cardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(18.sdp),
            child: _cardHeader(
              context:   context,
              icon:      widget.icon,
              iconColor: accent,
              title:     widget.title,
              subtitle:  widget.subtitle,
            ),
          ),
          if (widget.items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 24.sdp),
              child: Center(child: _EmptyState()),
            )
          else
            AnimatedSize(
              duration:  const Duration(milliseconds: 250),
              curve:     Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  ...display.asMap().entries.map(
                        (e) => _buildItem(context, e.value, e.key, cs, accent),
                  ),
                  if (hasMore)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.sdp),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: cs.outlineVariant.withOpacity(0.10)),
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.sdp)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isExpanded ? 'Show Less' : 'View All (${widget.items.length})',
                              style: TextStyle(
                                fontSize:   12.ssp,
                                fontWeight: FontWeight.w600,
                                color:      accent.withOpacity(0.85),
                              ),
                            ),
                            SizedBox(width: 4.sdp),
                            PhosphorIcon(
                              _isExpanded ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold) : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                              color: accent.withOpacity(0.85),
                              size:  12.sdp,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext ctx, dynamic item, int idx, ColorScheme cs, Color accent) {
    final val          = item[widget.valueKey] ?? 0;
    final displayValue = widget.isDuration ? _formatDuration(val) : '$val ${widget.suffix}';
    final title        = item[widget.titleKey]?.toString() ?? 'Unknown';

    String? sub;
    if (widget.subtitleKey != null && item[widget.subtitleKey] != null) {
      sub = widget.subtitleAsPill
          ? item[widget.subtitleKey].toString()
          : '${item[widget.subtitleKey]} ${widget.subtitleSuffix}'.trim();
    }

    return Padding(
      padding: EdgeInsets.only(left: 18.sdp, right: 18.sdp, bottom: 14.sdp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.sdp,
            child: Text(
              '${idx + 1}.',
              style: TextStyle(
                fontSize:   12.ssp,
                fontWeight: FontWeight.w500,
                color:      cs.onSurfaceVariant.withOpacity(0.50),
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
                  style: TextStyle(
                    fontSize:   13.ssp,
                    fontWeight: FontWeight.w600,
                    color:      cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  SizedBox(height: 4.sdp),
                  widget.subtitleAsPill
                      ? _Pill(label: sub, color: accent)
                      : Text(
                    sub,
                    style: TextStyle(
                      fontSize:   11.ssp,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant.withOpacity(0.60),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.sdp),
          _Pill(label: displayValue, color: accent, fontSize: 11.ssp),
        ],
      ),
    );
  }
}

// ─── Doughnut Chart ───────────────────────────────────────────────────────────
class _CallTypeDoughnutChart extends StatelessWidget {
  final List<dynamic> breakdown;
  const _CallTypeDoughnutChart({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    int incoming = 0, outgoing = 0, missed = 0;
    for (var item in breakdown) {
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
      decoration: _cardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.sdp, height: 36.sdp,
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
          Row(
            children: [
              SizedBox(
                height: 120.sdp, width: 120.sdp,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace:     3,
                        centerSpaceRadius: 38.sdp,
                        sections: [
                          if (incoming > 0)
                            PieChartSectionData(color: incomingColor.withOpacity(0.82), value: incoming.toDouble(), title: '', radius: 16.sdp),
                          if (outgoing > 0)
                            PieChartSectionData(color: outgoingColor.withOpacity(0.82), value: outgoing.toDouble(), title: '', radius: 16.sdp),
                          if (missed > 0)
                            PieChartSectionData(color: missedColor.withOpacity(0.82), value: missed.toDouble(), title: '', radius: 16.sdp),
                        ],
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeInOutCubic,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: TextStyle(fontSize: 20.ssp, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.0),
                        ),
                        SizedBox(height: 2.sdp),
                        Text('Total', style: TextStyle(fontSize: 10.ssp, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24.sdp),
              Expanded(
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Indicator(color: incomingColor, label: 'Incoming', value: incoming, total: total),
                    SizedBox(height: 14.sdp),
                    _Indicator(color: outgoingColor, label: 'Outgoing', value: outgoing, total: total),
                    SizedBox(height: 14.sdp),
                    _Indicator(color: missedColor, label: 'Missed', value: missed, total: total),
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

class _Indicator extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;

  const _Indicator({required this.color, required this.label, required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final pct = total > 0 ? (value / total * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 8.sdp, height: 8.sdp,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.80)),
        ),
        SizedBox(width: 8.sdp),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12.ssp, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant.withOpacity(0.80))),
        ),
        Text(value.toString(), style: TextStyle(fontSize: 13.ssp, fontWeight: FontWeight.w700, color: cs.onSurface)),
        SizedBox(width: 4.sdp),
        Text('($pct%)', style: TextStyle(fontSize: 10.ssp, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant.withOpacity(0.50))),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.sdp),
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize:   13.ssp,
            fontWeight: FontWeight.w400,
            color:      cs.onSurfaceVariant.withOpacity(0.50),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Loader ──────────────────────────────────────────────────────────
class _AnalyticsSkeletonLoader extends StatelessWidget {
  const _AnalyticsSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor:      cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _skeletonBox(160.sdp),
          SizedBox(height: 16.sdp),
          ...List.generate(
            4,
                (_) => Padding(
              padding: EdgeInsets.only(bottom: 16.sdp),
              child:   _skeletonBox(180.sdp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(double h) => Container(
    height: h,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
  );
}

// ─── Employee Filter Dropdown ─────────────────────────────────────────────────
class _EmployeeFilterDropdown extends StatelessWidget {
  const _EmployeeFilterDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CallLogAnalyticsViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sdp),
      padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 2.sdp),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.20), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.searchName,
          hint: Text(
            'All Employees',
            style: TextStyle(fontSize: 13.ssp, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
          ),
          isExpanded: true,
          icon: PhosphorIcon(PhosphorIcons.caretDown(PhosphorIconsStyle.bold), size: 14.sdp, color: cs.onSurfaceVariant),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All Employees', style: TextStyle(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
            ),
            ...vm.employees.map((e) {
              final empName = e.username;
              return DropdownMenuItem<String>(
                value: empName,
                child: Text(empName, style: TextStyle(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
              );
            }),
          ],
          onChanged: (val) {
            vm.setSearchName(val);
          },
        ),
      ),
    );
  }
}