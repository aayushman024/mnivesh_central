import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';
import '../../Widgets/RouteManagement/visit_details_components.dart';

class ViewRouteDetailsScreen extends StatefulWidget {
  const ViewRouteDetailsScreen({super.key});

  @override
  State<ViewRouteDetailsScreen> createState() => _ViewRouteDetailsScreenState();
}

class _ViewRouteDetailsScreenState extends State<ViewRouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const String _originTitle = 'Delhi Head Office';

  late final RouteOptimizationViewModel _viewModel;
  TabController? _tabController;

  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
    _viewModel.addListener(_handleViewModelChange);
    Future.microtask(_viewModel.loadAssignedRouteSummaries);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelectionChange);
    _tabController?.dispose();
    _viewModel.removeListener(_handleViewModelChange);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleTabSelectionChange() {
    if (mounted) setState(() {});
  }

  void _handleViewModelChange() {
    _syncTabController();
  }

  void _syncTabController() {
    final length = _viewModel.assignedRouteSummaries.length;
    if (length == 0) {
      if (_tabController != null) {
        _tabController!.dispose();
        _tabController = null;
        if (mounted) setState(() {});
      }
      return;
    }

    final needsNewController =
        _tabController == null || _tabController!.length != length;
    if (!needsNewController) return;

    final previousIndex = _tabController?.index ?? 0;
    final nextIndex = previousIndex < length ? previousIndex : length - 1;
    _tabController?.removeListener(_handleTabSelectionChange);
    _tabController?.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: nextIndex,
    );
    _tabController!.addListener(_handleTabSelectionChange);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'View Route Details', isBackIcon: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final summaries = _viewModel.assignedRouteSummaries;

          return Column(
            children: [
              SizedBox(height: 8.sdp),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32.sdp),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 24.sdp,
                        offset: Offset(0, -4.sdp),
                      ),
                    ],
                  ),
                  child: _buildBody(theme, summaries),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<AssignedRouteSummary> summaries) {
    if (_viewModel.isRouteDetailsLoading && summaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.routeDetailsErrorMessage != null && summaries.isEmpty) {
      return VisitStateView(
        title: 'Unable to load route details',
        message: _viewModel.routeDetailsErrorMessage!,
        actionLabel: 'Retry',
        onPressed: _viewModel.loadAssignedRouteSummaries,
      );
    }

    if (summaries.isEmpty) {
      return VisitStateView(
        title: 'No route details available',
        message: 'Assigned field executive routes for today will appear here.',
        actionLabel: 'Refresh',
        onPressed: _viewModel.loadAssignedRouteSummaries,
      );
    }

    final controller = _tabController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 16.sdp,),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.sdp),
          child: _buildTabBar(theme, controller, summaries),
        ),
        SizedBox(height: 16.sdp),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: summaries
                .map((summary) => _buildRouteTab(theme, summary))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(
    ThemeData theme,
    TabController controller,
    List<AssignedRouteSummary> summaries,
  ) {
    final isScrollable = summaries.length > 3;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(18.sdp),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
        labelColor: theme.colorScheme.primary,
        enableFeedback: true,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(2.sdp),
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.sdp),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 8.sdp,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: summaries.map((summary) {
          return Tab(
            height: 54.sdp,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.sdp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.feName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bold.custom(
                      12.ssp,
                    ),
                  ),
                  SizedBox(height: 2.sdp),
                  Text(
                    summary.visits.length>1 ? '${summary.visits.length} visits' : '${summary.visits.length} visit',
                    style: AppTextStyle.normal.custom(
                      11.ssp,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteTab(ThemeData theme, AssignedRouteSummary summary) {
    return RefreshIndicator.adaptive(
      onRefresh: _viewModel.loadAssignedRouteSummaries,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20.sdp, 12.sdp, 20.sdp, 28.sdp),
        children: [
          _buildStartNode(theme),
          if (summary.visits.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 20.sdp),
              child: VisitStateView(
                title: 'No stops assigned',
                message:
                    'This field executive does not have any visits assigned yet.',
                actionLabel: 'Refresh',
                onPressed: _viewModel.loadAssignedRouteSummaries,
              ),
            )
          else
            ...summary.visits.map(
              (visit) => Column(
                children: [
                  _buildTravelConnector(theme, visit.fromLastDestination),
                  _buildVisitCard(theme, visit),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartNode(ThemeData theme) {
    const greenerColor = Color(0xFF15803D);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineMarker(
          theme,
          icon: PhosphorIcons.buildings(),
          color: greenerColor,
        ),
        SizedBox(width: 14.sdp),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.sdp),
            decoration: BoxDecoration(
              color: greenerColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18.sdp),
              border: Border.all(
                color: greenerColor.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _originTitle,
                  style: AppTextStyle.extraBold.custom(
                    15.ssp,
                    theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.sdp),
                Text(
                  'Route origin',
                  style: AppTextStyle.normal.custom(
                    12.ssp,
                    theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelConnector(ThemeData theme, RouteTravelMetric? metric) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sdp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42.sdp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 1.5.sdp,
                  height: 16.sdp,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                Container(
                  width: 24.sdp,
                  height: 24.sdp,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.2.sdp,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.arrowDown(),
                    color: theme.colorScheme.primary,
                    size: 13.sdp,
                  ),
                ),
                Container(
                  width: 1.5.sdp,
                  height: 16.sdp,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.sdp),
          Expanded(
            child: Wrap(
              spacing: 8.sdp,
              runSpacing: 6.sdp,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildPremiumMetricPill(
                  theme,
                  icon: PhosphorIcons.ruler(),
                  value: metric?.distance ?? '--',
                  label: 'Distance',
                  color: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
                _buildPremiumMetricPill(
                  theme,
                  icon: PhosphorIcons.clockCountdown(),
                  value: metric?.expectedTime ?? '--',
                  label: 'ETA',
                  color: const Color(0xFFEA580C),
                  backgroundColor: const Color(0xFFFFF7ED),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMetricPill(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final resolvedBgColor = isDark ? color.withValues(alpha: 0.15) : backgroundColor;
    final resolvedTextColor = isDark ? color.withValues(alpha: 0.9) : color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(
          color: resolvedTextColor.withValues(alpha: 0.15),
          width: 1.sdp,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13.sdp,
            color: resolvedTextColor,
          ),
          SizedBox(width: 6.sdp),
          Text(
            '$label: ',
            style: AppTextStyle.bold.custom(
              11.ssp,
              resolvedTextColor.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: AppTextStyle.extraBold.custom(
              11.ssp,
              isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(ThemeData theme, AssignedRouteVisit visit) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sdp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineMarker(
            theme,
            icon: PhosphorIcons.mapPin(),
            color: _statusColor(visit.status),
          ),
          SizedBox(width: 14.sdp),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.sdp),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18.sdp),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 12.sdp,
                    offset: Offset(0, 4.sdp),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.clientName,
                              style: AppTextStyle.extraBold.custom(
                                15.ssp,
                                theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.sdp),
                            Text(
                              visit.purposeOfVisit,
                              style: AppTextStyle.normal.custom(
                                12.ssp,
                                theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(theme, visit.status),
                    ],
                  ),
                  SizedBox(height: 14.sdp),
                  Wrap(
                    spacing: 8.sdp,
                    runSpacing: 8.sdp,
                    children: [
                      _buildInfoPill(
                        theme,
                        icon: PhosphorIcons.clock(),
                        label: _formatTimeRange(visit.timings),
                      ),
                      if (visit.location.clientLocality != '-')
                        _buildInfoPill(
                          theme,
                          icon: PhosphorIcons.navigationArrow(),
                          label: visit.location.clientLocality,
                        ),
                    ],
                  ),
                  SizedBox(height: 12.sdp),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.mapPinLine(),
                        size: 18.sdp,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 10.sdp),
                      Expanded(
                        child: Text(
                          visit.location.shortAddress,
                          style: AppTextStyle.normal.custom(
                            12.ssp,
                            theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(
    ThemeData theme, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 42.sdp,
      height: 42.sdp,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 18.sdp),
    );
  }



  Widget _buildInfoPill(
    ThemeData theme, {
    required IconData icon,
    required String label,
    bool expanded = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14.sdp),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sdp, color: theme.colorScheme.primary),
          SizedBox(width: 8.sdp),
          if (expanded)
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bold.custom(
                  11.ssp,
                  theme.colorScheme.onSurface,
                ),
              ),
            )
          else
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bold.custom(
                11.ssp,
                theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.sdp),
      ),
      child: Text(
        _capitalize(status),
        style: AppTextStyle.bold.custom(11.ssp, color),
      ),
    );
  }

  String _formatTimeRange(AssignedRouteVisitTimings timings) {
    final start = timings.start;
    final end = timings.end;
    if (start == null && end == null) return 'Time unavailable';
    if (start != null && end != null) {
      return '${_timeFormat.format(start)} - ${_timeFormat.format(end)}';
    }
    return _timeFormat.format(start ?? end!);
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'on-hold':
      case 'hold':
        return Colors.orange;
      case 'cancelled':
      case 'closed':
        return Colors.redAccent;
      default:
        return themeAwarePendingColor(context);
    }
  }

  Color themeAwarePendingColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
  }
}
