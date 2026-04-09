import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mnivesh_central/Views/Widgets/ModuleAppBar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Models/callyn_analytics_model.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/callynAnalytics_viewModel.dart';
import '../Widgets/CallynAnalytics/CallTypeDoughnut.dart';
import '../Widgets/CallynAnalytics/EmployeeDropdown.dart';
import '../Widgets/CallynAnalytics/ExpandableListCard.dart';
import '../Widgets/CallynAnalytics/FilterTabs.dart';
import '../Widgets/CallynAnalytics/HorizontalBarGraph.dart';
import '../Widgets/CallynAnalytics/SingleEmployeeSummary.dart';

class CallynAnalyticsScreen extends StatelessWidget {
  const CallynAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return ChangeNotifierProvider(
      create: (_) => CallLogAnalyticsViewModel(),
      child: const _AnalyticsView(),
    );
  }
}

// ─── Root view — ZERO VM reads. Rebuilds only on Theme change. ────────────────

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModuleAppBar(title: "Callyn Analytics"),
      body: Column(
        children: [
          SizedBox(height: 8.sdp),
          const Expanded(child: _AnalyticsSheet()),
        ],
      ),
    );
  }
}

// ─── Sheet container — ZERO VM reads. Rebuilds only on Theme change. ──────────
//
// Keeps the rounded container, drag handle, and header widgets stable so that
// data loading, errors, or filter changes never cause them to repaint.

class _AnalyticsSheet extends StatelessWidget {
  const _AnalyticsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 24.sdp,
            offset: Offset(0, -6.sdp),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
        child: Column(
          children: [
            SizedBox(height: 20.sdp),
            // Each child carries its own granular context.select subscriptions,
            // so they rebuild independently of each other and of this widget.
            const EmployeeFilterDropdown(),
            SizedBox(height: 12.sdp),
            const AnalyticsFilterTabs(),
            SizedBox(height: 4.sdp),
            const Expanded(child: _AnalyticsBody()),
          ],
        ),
      ),
    );
  }
}

// ─── Body gate — reads ONLY isLoading + errorMessage. ────────────────────────
//
// When data finishes loading, only this widget and its subtree rebuild.
// The Scaffold, AppBar, and sheet container above remain untouched.

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (CallLogAnalyticsViewModel v) => v.isLoading,
    );
    final errorMessage = context.select(
      (CallLogAnalyticsViewModel v) => v.errorMessage,
    );

    if (isLoading) return const _AnalyticsSkeletonBody();
    if (errorMessage != null) return _ErrorView(message: errorMessage);
    return const _DataBody();
  }
}

class _AnalyticsSkeletonBody extends StatelessWidget {
  const _AnalyticsSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16.sdp,
          right: 16.sdp,
          top: 16.sdp,
          bottom: 80.sdp,
        ),
        children: [
          _SkeletonCard(
            child: Row(
              children: [
                Container(
                  width: 36.sdp,
                  height: 36.sdp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.sdp),
                  ),
                ),
                SizedBox(width: 12.sdp),
                const Expanded(
                  child: Text(
                    'Call Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.sdp),
          _SkeletonCard(
            child: Column(
              children: List.generate(3, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14.sdp),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Employee Name',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(width: 10.sdp),
                      const Text('00 calls', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 16.sdp),
          _SkeletonCard(
            child: Column(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 3 ? 0 : 14.sdp),
                  child: Row(
                    children: [
                      const Text('1.', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 8.sdp),
                      const Expanded(
                        child: Text(
                          'Client Name',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(width: 12.sdp),
                      const Text('00 calls', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Widget child;

  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(18.sdp),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.sdp),
      ),
      child: child,
    );
  }
}

// ─── Data body — reads ONLY analyticsData + searchName. ──────────────────────
//
// Separated from _AnalyticsBody so switching between single / all-employee
// view does NOT re-trigger the loading / error gate above it.

class _DataBody extends StatelessWidget {
  const _DataBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = context.select(
      (CallLogAnalyticsViewModel v) => v.analyticsData,
    );
    final isSingleEmployee = context.select(
      (CallLogAnalyticsViewModel v) => v.searchName != null,
    );

    if (data == null) return const SizedBox.shrink();

    return RefreshIndicator.adaptive(
      // Lambda wrapper: context.read is safe inside callbacks and avoids
      // capturing a stale method reference during build.
      onRefresh: () => context.read<CallLogAnalyticsViewModel>().fetchData(),
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16.sdp,
          right: 16.sdp,
          top: 16.sdp,
          bottom: 80.sdp,
        ),
        // Static methods: no `this` capture, no closure allocation per call.
        children: isSingleEmployee
            ? _buildSingleEmployee(data)
            : _buildAllEmployees(data),
      ),
    );
  }

  // ── Static widget-list builders ───────────────────────────────────────────

  static List<Widget> _buildSingleEmployee(CallLogAnalyticsModel data) => [
    SingleEmployeeSummary(data: data),
    SizedBox(height: 16.sdp),
    CallTypeDoughnutChart(breakdown: data.callTypeBreakdown),
    SizedBox(height: 16.sdp),
    ExpandableListCard(
      title: 'Most Called Contacts',
      subtitle: 'By Call Frequency',
      icon: PhosphorIcons.buildings(PhosphorIconsStyle.fill),
      items: data.mostFrequentlyCalledClients,
      titleKey: 'client',
      subtitleKey: 'familyHead',
      subtitleAsPill: true,
      valueKey: 'callCount',
      suffix: 'calls',
      iconColor: GraphColors.mostCalled,
    ),
    SizedBox(height: 16.sdp),
    ExpandableListCard(
      title: 'Longest Contact Calls',
      subtitle: 'By Total Duration',
      icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
      items: data.mostCalledClientsByDuration,
      titleKey: 'client',
      subtitleKey: 'familyHead',
      subtitleAsPill: true,
      valueKey: 'totalDuration',
      isDuration: true,
      iconColor: GraphColors.workDuration,
    ),
  ];

  static List<Widget> _buildAllEmployees(CallLogAnalyticsModel data) => [
    CallTypeDoughnutChart(breakdown: data.callTypeBreakdown),
    SizedBox(height: 16.sdp),
    HorizontalBarGraphCard(
      title: 'Top Call Volume',
      subtitle: 'By Employee',
      icon: PhosphorIcons.phoneCall(PhosphorIconsStyle.fill),
      items: data.mostCallsMade,
      titleKey: 'employee',
      valueKey: 'totalCalls',
      suffix: 'calls',
      barColor: GraphColors.topVolume,
    ),
    SizedBox(height: 16.sdp),
    HorizontalBarGraphCard(
      title: 'Longest Work Calls',
      subtitle: 'Total Duration/Employee',
      icon: PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
      items: data.mostWorkCallDuration,
      titleKey: 'employee',
      valueKey: 'totalWorkDuration',
      isDuration: true,
      barColor: GraphColors.workDuration,
    ),
    SizedBox(height: 16.sdp),
    HorizontalBarGraphCard(
      title: 'Longest Personal Calls',
      subtitle: 'Total Duration/Employee',
      icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
      items: data.mostPersonalCallDuration,
      titleKey: 'employee',
      valueKey: 'totalPersonalDuration',
      isDuration: true,
      barColor: GraphColors.personalDur,
    ),
    SizedBox(height: 16.sdp),
    HorizontalBarGraphCard(
      title: 'Missed / Rejected Calls',
      subtitle: 'By Employee',
      icon: PhosphorIcons.phoneDisconnect(PhosphorIconsStyle.fill),
      items: data.missedOrRejectedPerEmployee,
      titleKey: 'employee',
      valueKey: 'missedOrRejected',
      suffix: 'calls',
      barColor: GraphColors.missedCalls,
    ),
    SizedBox(height: 16.sdp),
    ExpandableListCard(
      title: 'Avg Call Duration',
      subtitle: 'Per Employee',
      icon: PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
      items: data.avgCallDurationPerEmployee,
      titleKey: 'employee',
      subtitleKey: 'totalCalls',
      subtitleSuffix: 'total calls',
      valueKey: 'avgDuration',
      isDuration: true,
      iconColor: GraphColors.avgDuration,
    ),
    SizedBox(height: 16.sdp),
    ExpandableListCard(
      title: 'Most Called Contacts',
      subtitle: 'By Call Frequency',
      icon: PhosphorIcons.buildings(PhosphorIconsStyle.fill),
      items: data.mostFrequentlyCalledClients,
      titleKey: 'client',
      subtitleKey: 'familyHead',
      subtitleAsPill: true,
      valueKey: 'callCount',
      suffix: 'calls',
      iconColor: GraphColors.mostCalled,
    ),
    SizedBox(height: 16.sdp),
    ExpandableListCard(
      title: 'Longest Contact Calls',
      subtitle: 'By Total Duration',
      icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
      items: data.mostCalledClientsByDuration,
      titleKey: 'client',
      subtitleKey: 'familyHead',
      subtitleAsPill: true,
      valueKey: 'totalDuration',
      isDuration: true,
      iconColor: GraphColors.workDuration,
    ),
  ];
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
            size: 48.sdp,
            color: cs.error,
          ),
          SizedBox(height: 16.sdp),
          Text(
            message,
            style: AppTextStyle.normal
                .normal(cs.error)
                .copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20.sdp),
          FilledButton.icon(
            // context.read in a callback — correct Provider pattern.
            onPressed: () =>
                context.read<CallLogAnalyticsViewModel>().fetchData(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
