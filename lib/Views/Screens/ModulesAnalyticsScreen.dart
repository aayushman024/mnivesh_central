import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../Models/modules_analytics_model.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/modules_analytics_viewModel.dart';
import '../Widgets/ModuleAppBar.dart';

class ModulesAnalyticsScreen extends StatefulWidget {
  const ModulesAnalyticsScreen({super.key});

  @override
  State<ModulesAnalyticsScreen> createState() => _ModulesAnalyticsScreenState();
}

class _ModulesAnalyticsScreenState extends State<ModulesAnalyticsScreen> {
  late final ModulesAnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ModulesAnalyticsViewModel();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return _ModulesAnalyticsView(viewModel: _viewModel);
  }
}

class _ModulesAnalyticsView extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _ModulesAnalyticsView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'Modules Analytics'),
      body: Column(
        children: [
          SizedBox(height: 8.sdp),
          Expanded(child: _ModulesAnalyticsBody(viewModel: viewModel)),
        ],
      ),
    );
  }
}

class _ModulesAnalyticsBody extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _ModulesAnalyticsBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.06),
                blurRadius: 24.sdp,
                offset: Offset(0, -6.sdp),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp)),
            child: Column(
              children: [
                SizedBox(height: 18.sdp),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sdp),
                  child: _FiltersRow(viewModel: viewModel),
                ),
                SizedBox(height: 10.sdp),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sdp),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _rangeLabel(viewModel.dateRange),
                          style: AppTextStyle.normal.small(
                            onSurface.withOpacity(0.55),
                          ),
                        ),
                      ),
                      Icon(
                        viewModel.isDescending
                            ? PhosphorIcons.sortDescending()
                            : PhosphorIcons.sortAscending(),
                        size: 16.sdp,
                        color: onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.sdp),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (viewModel.isLoading) {
                        return const _ModulesAnalyticsSkeleton();
                      }
                      if (viewModel.errorMessage != null) {
                        return _ErrorState(
                          message: viewModel.errorMessage!,
                          viewModel: viewModel,
                        );
                      }
                      if (viewModel.modules.isEmpty) {
                        return const _EmptyState();
                      }
                      return _AnalyticsContent(viewModel: viewModel);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _rangeLabel(DateTimeRange range) {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(range.start)} to ${formatter.format(range.end)}';
  }
}

class _FiltersRow extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _FiltersRow({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Today',
                  selected:
                      viewModel.rangeSelection == DateTimeRangeSelection.today,
                  onTap: () =>
                      viewModel.selectPreset(DateTimeRangeSelection.today),
                ),
                _FilterChip(
                  label: '7 Days',
                  selected:
                      viewModel.rangeSelection ==
                      DateTimeRangeSelection.last7Days,
                  onTap: () =>
                      viewModel.selectPreset(DateTimeRangeSelection.last7Days),
                ),
                _FilterChip(
                  label: '30 Days',
                  selected:
                      viewModel.rangeSelection ==
                      DateTimeRangeSelection.last30Days,
                  onTap: () =>
                      viewModel.selectPreset(DateTimeRangeSelection.last30Days),
                ),
                _FilterChip(
                  label: 'Custom',
                  selected:
                      viewModel.rangeSelection == DateTimeRangeSelection.custom,
                  onTap: () => _pickCustomRange(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.sdp),
        IconButton.filledTonal(
          onPressed: viewModel.toggleSortOrder,
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
          ),
          icon: Icon(
            viewModel.isDescending
                ? PhosphorIcons.funnelSimple()
                : PhosphorIcons.funnelSimpleX(),
            size: 18.sdp,
          ),
          tooltip: viewModel.isDescending ? 'Most to least' : 'Least to most',
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: viewModel.dateRange,
    );

    if (picked != null) {
      await viewModel.setCustomRange(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(right: 8.sdp),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary.withOpacity(0.16),
        labelStyle: AppTextStyle.bold.small(
          selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _AnalyticsContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.sdp, 8.sdp, 20.sdp, 32.sdp),
      children: [
        _SectionHeader(
          title: 'Module Total Counts',
          subtitle: 'Sorted by total taps for the selected range',
        ),
        SizedBox(height: 12.sdp),
        SizedBox(
          height: 118.sdp,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.modules.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
            itemBuilder: (context, index) {
              final module = viewModel.modules[index];
              return _SummaryCard(
                moduleName: module.moduleName,
                totalTaps: module.totalTaps,
                usersCount: module.recentUsers.length,
              );
            },
          ),
        ),
        SizedBox(height: 24.sdp),
        _SectionHeader(
          title: 'Users Accessed in Last 24 Hours',
          subtitle:
              'Module rows are sorted globally. Expand a row to inspect recent users and daily records.',
        ),
        SizedBox(height: 12.sdp),
        ...viewModel.modules.map(
          (module) => Padding(
            padding: EdgeInsets.only(bottom: 12.sdp),
            child: _ModuleExpansionCard(module: module),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.extraBold.normal(theme.colorScheme.onSurface),
        ),
        SizedBox(height: 4.sdp),
        Text(
          subtitle,
          style: AppTextStyle.normal.small(
            theme.colorScheme.onSurface.withOpacity(0.58),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String moduleName;
  final int totalTaps;
  final int usersCount;

  const _SummaryCard({
    required this.moduleName,
    required this.totalTaps,
    required this.usersCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220.sdp,
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.sdp),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
          ),
          const Spacer(),
          Text(
            totalTaps.toString(),
            style: AppTextStyle.extraBold.custom(
              24.sdp,
              theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 4.sdp),
          Text(
            '$usersCount users',
            style: AppTextStyle.normal.small(
              theme.colorScheme.onSurface.withOpacity(0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleExpansionCard extends StatelessWidget {
  final ModuleAnalyticsGroup module;

  const _ModuleExpansionCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.14)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 4.sdp),
        childrenPadding: EdgeInsets.fromLTRB(16.sdp, 0, 16.sdp, 16.sdp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.sdp),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.sdp),
        ),
        title: Text(
          module.moduleName,
          style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          '${module.totalTaps} total taps',
          style: AppTextStyle.normal.small(
            theme.colorScheme.onSurface.withOpacity(0.58),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 6.sdp),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${module.recentUsers.length} users',
            style: AppTextStyle.bold.small(theme.colorScheme.primary),
          ),
        ),
        children: [
          _SubSectionTitle(title: 'Users accessed in last 24 hours'),
          if (module.recentUsers.isEmpty)
            const _InlineEmptyState(message: 'No users found for this module.')
          else
            ...module.recentUsers.map((user) => _UserRow(user: user)),
          SizedBox(height: 16.sdp),
          _SubSectionTitle(title: 'Expandable records for last 30 days'),
          if (module.records.isEmpty)
            const _InlineEmptyState(message: 'No daily records available.')
          else
            ...module.records.map((record) => _RecordRow(record: record)),
        ],
      ),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  final String title;

  const _SubSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.sdp),
      child: Text(
        title,
        style: AppTextStyle.bold.small(theme.colorScheme.onSurface),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final ModuleUserAccessRecord user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 8.sdp),
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 12.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14.sdp),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.userCircle(),
            size: 18.sdp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 10.sdp),
          Expanded(
            child: Text(
              user.email,
              style: AppTextStyle.normal.small(theme.colorScheme.onSurface),
            ),
          ),
          SizedBox(width: 12.sdp),
          Text(
            '${user.taps}',
            style: AppTextStyle.bold.normal(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final ModuleTapSummaryRecord record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM yyyy');

    return Container(
      margin: EdgeInsets.only(bottom: 8.sdp),
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 12.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14.sdp),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatter.format(record.date),
              style: AppTextStyle.normal.small(theme.colorScheme.onSurface),
            ),
          ),
          Text(
            '${record.totalTaps} taps',
            style: AppTextStyle.bold.small(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _ModulesAnalyticsSkeleton extends StatelessWidget {
  const _ModulesAnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.sdp, 8.sdp, 20.sdp, 24.sdp),
        children: [
          const _SectionHeader(
            title: 'Module Total Counts',
            subtitle: 'Sorted by total taps for the selected range',
          ),
          SizedBox(height: 12.sdp),
          SizedBox(
            height: 118.sdp,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
              itemBuilder: (_, __) => Container(
                width: 220.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.sdp),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.sdp),
          const _SectionHeader(
            title: 'Users Accessed in Last 24 Hours',
            subtitle: 'Module rows are sorted globally.',
          ),
          SizedBox(height: 12.sdp),
          ...List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 12.sdp),
              child: Container(
                height: 88.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.sdp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final ModulesAnalyticsViewModel viewModel;

  const _ErrorState({required this.message, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warningCircle(),
              size: 36.sdp,
              color: Colors.redAccent,
            ),
            SizedBox(height: 10.sdp),
            Text(
              'Failed to load analytics',
              style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
            ),
            SizedBox(height: 6.sdp),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.normal.small(
                theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16.sdp),
            FilledButton(onPressed: viewModel.load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.chartBar(),
              size: 34.sdp,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
            SizedBox(height: 10.sdp),
            Text(
              'No module analytics available',
              style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
            ),
            SizedBox(height: 6.sdp),
            Text(
              'Try selecting a different date range.',
              style: AppTextStyle.normal.small(
                theme.colorScheme.onSurface.withOpacity(0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.sdp),
      child: Text(
        message,
        style: AppTextStyle.normal.small(
          theme.colorScheme.onSurface.withOpacity(0.58),
        ),
      ),
    );
  }
}
