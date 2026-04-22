import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Models/modules_analytics_model.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/modules_analytics_viewModel.dart';
import '../Widgets/ModuleAppBar.dart';

// lookup helper to find module config (icon/color) by its string name
ModuleItem? _getModuleConfig(String name) {
  for (final item in appModules) {
    if (item.title.toLowerCase() == name.toLowerCase()) {
      return item;
    }
  }
  return null;
}

class ModulesAnalyticsScreen extends StatefulWidget {
  const ModulesAnalyticsScreen({super.key});

  @override
  State<ModulesAnalyticsScreen> createState() => _ModulesAnalyticsScreenState();
}

class _ModulesAnalyticsScreenState extends State<ModulesAnalyticsScreen> {
  late final ModulesAnalyticsViewModel _moduleAnalyticsViewModel;

  @override
  void initState() {
    super.initState();
    _moduleAnalyticsViewModel = ModulesAnalyticsViewModel();
    _moduleAnalyticsViewModel.load();
  }

  @override
  void dispose() {
    _moduleAnalyticsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'Modules Analytics'),
      body: _ModulesAnalyticsBody(viewModel: _moduleAnalyticsViewModel),
    );
  }
}

class _ModulesAnalyticsBody extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _ModulesAnalyticsBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.04),
                blurRadius: 20.sdp,
                offset: Offset(0, -4.sdp),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
            child: Column(
              children: [
                SizedBox(height: 20.sdp),
                _FiltersHeader(viewModel: viewModel),
                SizedBox(height: 16.sdp),
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
}

class _FiltersHeader extends StatelessWidget {
  final ModulesAnalyticsViewModel viewModel;

  const _FiltersHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM yyyy');
    final rangeLabel =
        '${formatter.format(viewModel.dateRange.start)} - ${formatter.format(viewModel.dateRange.end)}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Today',
                        isSelected:
                        viewModel.rangeSelection ==
                            DateTimeRangeSelection.today,
                        onTap:
                            () => viewModel.selectPreset(
                          DateTimeRangeSelection.today,
                        ),
                      ),
                      _FilterPill(
                        label: '7D',
                        isSelected:
                        viewModel.rangeSelection ==
                            DateTimeRangeSelection.last7Days,
                        onTap:
                            () => viewModel.selectPreset(
                          DateTimeRangeSelection.last7Days,
                        ),
                      ),
                      _FilterPill(
                        label: '30D',
                        isSelected:
                        viewModel.rangeSelection ==
                            DateTimeRangeSelection.last30Days,
                        onTap:
                            () => viewModel.selectPreset(
                          DateTimeRangeSelection.last30Days,
                        ),
                      ),
                      _FilterPill(
                        label: 'Custom',
                        isSelected:
                        viewModel.rangeSelection ==
                            DateTimeRangeSelection.custom,
                        icon: PhosphorIcons.calendarBlank(),
                        onTap: () => _pickCustomRange(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.sdp),
              InkWell(
                onTap: viewModel.toggleSortOrder,
                borderRadius: BorderRadius.circular(12.sdp),
                child: Container(
                  padding: EdgeInsets.all(10.sdp),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                      0.4,
                    ),
                    borderRadius: BorderRadius.circular(12.sdp),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    viewModel.isDescending
                        ? PhosphorIcons.sortDescending()
                        : PhosphorIcons.sortAscending(),
                    size: 18.sdp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sdp),
          Row(
            children: [
              Icon(
                PhosphorIcons.clockCounterClockwise(),
                size: 14.sdp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(width: 6.sdp),
              Text(
                rangeLabel,
                style: AppTextStyle.bold.small(
                  theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: viewModel.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await viewModel.setCustomRange(picked);
    }
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor =
    isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final textColor =
    isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.sdp),
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 8.sdp),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24.sdp),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.sdp, color: textColor),
              SizedBox(width: 6.sdp),
            ],
            Text(label, style: AppTextStyle.bold.small(textColor)),
          ],
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
    final maxTaps = viewModel.modules.fold<int>(
      0,
          (max, mod) => mod.totalTaps > max ? mod.totalTaps : max,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(20.sdp, 8.sdp, 20.sdp, 40.sdp),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Top Modules',
          style: AppTextStyle.extraBold.normal(
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.sdp),
        SizedBox(
          height: 130.sdp,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: viewModel.modules.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
            itemBuilder: (context, index) {
              return _TopModuleCard(module: viewModel.modules[index]);
            },
          ),
        ),
        SizedBox(height: 28.sdp),
        Text(
          'Detailed Usage',
          style: AppTextStyle.extraBold.normal(
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.sdp),
        ...viewModel.modules.map(
              (module) => Padding(
            padding: EdgeInsets.only(bottom: 12.sdp),
            child: _DetailedModuleCard(module: module, maxGlobalTaps: maxTaps),
          ),
        ),
      ],
    );
  }
}

class _TopModuleCard extends StatelessWidget {
  final ModuleAnalyticsGroup module;

  const _TopModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getModuleConfig(module.moduleName);

    // fallback colors/icons if module name doesn't match data model
    final moduleColor = config?.baseColor ?? theme.colorScheme.primary;
    final moduleIcon = config?.icon ?? PhosphorIcons.squaresFour(PhosphorIconsStyle.fill);

    return Container(
      width: 160.sdp,
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.02),
            blurRadius: 10.sdp,
            offset: Offset(0, 4.sdp),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.sdp),
                decoration: BoxDecoration(
                  color: moduleColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  moduleIcon,
                  size: 18.sdp,
                  color: moduleColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.sdp,
                  vertical: 4.sdp,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.sdp),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.users(),
                      size: 12.sdp,
                      color: theme.colorScheme.secondary,
                    ),
                    SizedBox(width: 4.sdp),
                    Text(
                      '${module.recentUsers.length}',
                      style: AppTextStyle.bold.small(
                        theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${module.totalTaps}',
            style: AppTextStyle.extraBold.custom(
              28.sdp,
              theme.colorScheme.onSurface,
            ),
          ),
          Text(
            module.moduleName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.bold.small(
              theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedModuleCard extends StatelessWidget {
  final ModuleAnalyticsGroup module;
  final int maxGlobalTaps;

  const _DetailedModuleCard({
    required this.module,
    required this.maxGlobalTaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getModuleConfig(module.moduleName);

    final moduleColor = config?.baseColor ?? theme.colorScheme.primary;
    final moduleIcon = config?.icon ?? PhosphorIcons.appWindow();

    final usageRatio =
    maxGlobalTaps > 0 ? module.totalTaps / maxGlobalTaps : 0.0;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 8.sdp),
        childrenPadding: EdgeInsets.fromLTRB(16.sdp, 0, 16.sdp, 16.sdp),
        collapsedBackgroundColor: theme.colorScheme.surfaceContainerHighest
            .withOpacity(0.3),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
          0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.sdp),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.sdp),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sdp),
              margin: EdgeInsets.only(right: 12.sdp),
              decoration: BoxDecoration(
                color: moduleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.sdp),
              ),
              child: Icon(moduleIcon, size: 20.sdp, color: moduleColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.moduleName,
                    style: AppTextStyle.bold.normal(
                      theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.sdp),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.sdp),
                          child: LinearProgressIndicator(
                            value: usageRatio,
                            minHeight: 6.sdp,
                            backgroundColor: theme.colorScheme.outline
                                .withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              moduleColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.sdp),
                      Text(
                        '${module.totalTaps} taps',
                        style: AppTextStyle.bold.small(moduleColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
          SizedBox(height: 8.sdp),
          _SectionTitle(title: 'Recent Users (24h)'),
          if (module.recentUsers.isEmpty)
            const _EmptyRow(message: 'No active users in last 24h')
          else
            ...module.recentUsers.map((u) => _UserRowTile(user: u, moduleColor: moduleColor)),
          SizedBox(height: 16.sdp),
          _SectionTitle(title: 'Daily Tap Records'),
          if (module.records.isEmpty)
            const _EmptyRow(message: 'No daily records')
          else
            ...module.records.map((r) => _RecordRowTile(record: r, moduleColor: moduleColor)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sdp),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTextStyle.bold.small(
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _UserRowTile extends StatelessWidget {
  final ModuleUserAccessRecord user;
  final Color moduleColor;

  const _UserRowTile({required this.user, required this.moduleColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 8.sdp),
      padding: EdgeInsets.all(12.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.sdp),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14.sdp,
            backgroundColor: moduleColor.withOpacity(0.1),
            child: Text(
              user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
              style: AppTextStyle.bold.small(moduleColor),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.email,
                  style: AppTextStyle.bold.small(theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.createdAt != null) ...[
                  SizedBox(height: 2.sdp),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(user.createdAt!.toLocal()),
                    style: AppTextStyle.normal.custom(10.sdp, theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 4.sdp),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.sdp),
            ),
            child: Text(
              '${user.taps} taps',
              style: AppTextStyle.bold.small(
                theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRowTile extends StatelessWidget {
  final ModuleTapSummaryRecord record;
  final Color moduleColor;

  const _RecordRowTile({required this.record, required this.moduleColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sdp, horizontal: 4.sdp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formatter.format(record.date),
            style: AppTextStyle.bold.small(
              theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          Text(
            '${record.totalTaps}',
            style: AppTextStyle.bold.normal(moduleColor),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;

  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.sdp),
      child: Text(
        message,
        style: AppTextStyle.bold.small(
          Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
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
          Text(
            'Top Modules',
            style: AppTextStyle.extraBold.normal(Colors.black),
          ),
          SizedBox(height: 12.sdp),
          SizedBox(
            height: 130.sdp,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: 12.sdp),
              itemBuilder: (_, __) => Container(
                width: 160.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.sdp),
                ),
              ),
            ),
          ),
          SizedBox(height: 28.sdp),
          Text(
            'Detailed Usage',
            style: AppTextStyle.extraBold.normal(Colors.black),
          ),
          SizedBox(height: 12.sdp),
          ...List.generate(
            4,
                (_) => Padding(
              padding: EdgeInsets.only(bottom: 12.sdp),
              child: Container(
                height: 70.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.sdp),
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
        padding: EdgeInsets.all(32.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                size: 32.sdp,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 16.sdp),
            Text(
              'Something went wrong',
              style: AppTextStyle.extraBold.normal(theme.colorScheme.onSurface),
            ),
            SizedBox(height: 8.sdp),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.bold.small(
                theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.sdp),
            FilledButton.icon(
              onPressed: viewModel.load,
              icon: Icon(PhosphorIcons.arrowsClockwise(), size: 16.sdp),
              label: const Text('Try Again'),
            ),
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
        padding: EdgeInsets.all(32.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                size: 32.sdp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            SizedBox(height: 16.sdp),
            Text(
              'No Analytics Found',
              style: AppTextStyle.extraBold.normal(theme.colorScheme.onSurface),
            ),
            SizedBox(height: 8.sdp),
            Text(
              'Adjust your date range filters to see module usage.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bold.small(
                theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}