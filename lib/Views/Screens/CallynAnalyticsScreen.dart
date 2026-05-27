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
  const CallynAnalyticsScreen({super.key});

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: ModuleAppBar(title: "Callyn Analytics"),
        body: Column(
          children: [
            SizedBox(height: 8.sdp),
            const Expanded(child: _AnalyticsSheet()),
          ],
        ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeBlue = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

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
            // Premium custom styled TabBar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sdp),
              child: Container(
                height: 48.sdp,
                padding: EdgeInsets.all(4.sdp),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24.sdp),
                  border: Border.all(color: cs.outline.withOpacity(0.08)),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: activeBlue.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(50.sdp),
                    border: Border.all(
                      color: activeBlue.withOpacity(isDark ? 0.3 : 0.2),
                      width:1.sdp,
                    ),
                  ),
                  labelColor: activeBlue,
                  unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                  labelStyle: AppTextStyle.bold.small(null),
                  unselectedLabelStyle: AppTextStyle.normal.small(null),
                  tabs: const [
                    Tab(text: 'Callyn Analytics'),
                    Tab(text: 'mRelay Stats'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.sdp),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: const [
                  _CallynAnalyticsTabContent(),
                  _MRelayStatsTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallynAnalyticsTabContent extends StatelessWidget {
  const _CallynAnalyticsTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AnalyticsFilterTabs(),
        SizedBox(height: 4),
        Expanded(child: _AnalyticsBody()),
      ],
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
          Skeleton.ignore(
            child: const EmployeeFilterDropdown(margin: EdgeInsets.zero),
          ),
          SizedBox(height: 16.sdp),
          const _SkeletonDoughnutCard(),
          SizedBox(height: 16.sdp),
          const _SkeletonBarGraphCard(),
          SizedBox(height: 16.sdp),
          const _SkeletonExpandableListCard(),
        ],
      ),
    );
  }
}

class _SkeletonDoughnutCard extends StatelessWidget {
  const _SkeletonDoughnutCard();

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.sdp,
                height: 32.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.sdp),
                ),
              ),
              SizedBox(width: 12.sdp),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Call Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.sdp),
                  const Text('All Call Types', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          SizedBox(height: 32.sdp),
          Center(
            child: Container(
              width: 180.sdp,
              height: 180.sdp,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 32.sdp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) =>
                  Container(width: 50.sdp, height: 16.sdp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBarGraphCard extends StatelessWidget {
  const _SkeletonBarGraphCard();

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.sdp,
                height: 32.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.sdp),
                ),
              ),
              SizedBox(width: 12.sdp),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Call Volume',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.sdp),
                  const Text('By Employee', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.sdp),
          Column(
            children: List.generate(5, (index) {
              final double barWidth = 200.sdp - (index * 30.sdp);
              return Padding(
                padding: EdgeInsets.only(bottom: index == 4 ? 0 : 16.sdp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Employee Name',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(width: 10.sdp),
                        const Text('000 calls', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 8.sdp),
                    Container(
                      width: barWidth > 20 ? barWidth : 20,
                      height: 8.sdp,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.sdp),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SkeletonExpandableListCard extends StatelessWidget {
  const _SkeletonExpandableListCard();

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.sdp,
                height: 32.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.sdp),
                ),
              ),
              SizedBox(width: 12.sdp),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most Called Contacts',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.sdp),
                  const Text(
                    'By Call Frequency',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.sdp),
          Column(
            children: List.generate(5, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 4 ? 0 : 14.sdp),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12.sdp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client Name Here',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 4.sdp),
                          Container(
                            width: 80.sdp,
                            height: 14.sdp,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.sdp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sdp),
                    const Text(
                      '00 calls',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
        children: [
          const EmployeeFilterDropdown(margin: EdgeInsets.zero),
          SizedBox(height: 16.sdp),
          ...(isSingleEmployee
              ? _buildSingleEmployee(data)
              : _buildAllEmployees(data)),
        ],
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

class _MRelayStatsTabContent extends StatefulWidget {
  const _MRelayStatsTabContent({Key? key}) : super(key: key);

  @override
  State<_MRelayStatsTabContent> createState() => _MRelayStatsTabContentState();
}

class _MRelayStatsTabContentState extends State<_MRelayStatsTabContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallLogAnalyticsViewModel>().fetchWhitelistStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final viewModel = context.watch<CallLogAnalyticsViewModel>();

    if (viewModel.isLoadingWhitelist) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (viewModel.whitelistErrorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.sdp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                size: 40.sdp,
                color: cs.error,
              ),
              SizedBox(height: 12.sdp),
              Text(
                viewModel.whitelistErrorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyle.bold.small(cs.error),
              ),
              SizedBox(height: 16.sdp),
              FilledButton.icon(
                onPressed: () => viewModel.fetchWhitelistStats(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.whitelistStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.info(PhosphorIconsStyle.regular),
              size: 40.sdp,
              color: cs.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 12.sdp),
            Text(
              'No whitelists found',
              style: AppTextStyle.bold.small(cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: () => viewModel.fetchWhitelistStats(),
      color: cs.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: viewModel.whitelistStats.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.sdp),
        itemBuilder: (context, index) {
          final item = viewModel.whitelistStats[index];
          return _WhitelistItemTile(item: item);
        },
      ),
    );
  }
}

class _WhitelistItemTile extends StatelessWidget {
  final WhitelistStatModel item;

  const _WhitelistItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12.sdp),
            ),
            child: Text(
              item.name,
              style: AppTextStyle.bold.small(cs.onPrimaryContainer),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Added by:',
                  style: AppTextStyle.normal.custom(10.sdp, cs.onSurface.withOpacity(0.4)),
                ),
                SizedBox(height: 2.sdp),
                Text(
                  item.uploadedBy.isNotEmpty ? item.uploadedBy : 'System',
                  style: AppTextStyle.bold.small(cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.sdp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
            decoration: BoxDecoration(
              color: item.count > 0 ? Colors.green.withOpacity(0.12) : cs.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.sdp),
              border: Border.all(
                color: item.count > 0 ? Colors.green.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14.sdp,
                  color: item.count > 0 ? Colors.green : cs.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 4.sdp),
                Text(
                  '${item.count}',
                  style: AppTextStyle.bold.small(
                    item.count > 0 ? Colors.green : cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

