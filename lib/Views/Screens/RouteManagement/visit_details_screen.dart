import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';
import '../../Widgets/RouteManagement/visit_cards.dart';
import '../../Widgets/RouteManagement/visit_details_components.dart';

class VisitDetailsScreen extends StatefulWidget {
  const VisitDetailsScreen({super.key});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> with SingleTickerProviderStateMixin {
  late final RouteOptimizationViewModel _viewModel;
  late final TabController _tabController;
  late final TextEditingController _assignedSearchController;
  late final TextEditingController _onHoldSearchController;
  late final TextEditingController _completedSearchController;
  
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
    _tabController = TabController(length: 3, vsync: this);
    _assignedSearchController = TextEditingController();
    _onHoldSearchController = TextEditingController();
    _completedSearchController = TextEditingController();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _viewModel.setVisitTabIndex(_tabController.index);
      }
    });
    
    Future.microtask(_viewModel.initializeVisitDetails);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assignedSearchController.dispose();
    _onHoldSearchController.dispose();
    _completedSearchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'Visit Details', isBackIcon: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          _syncControllers();
          return Column(
            children: [
              SizedBox(height: 8.sdp),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: _sheetDecoration(theme),
                  child: Column(
                    children: [
                      _buildTabBar(theme),
                      SizedBox(height: 16.sdp),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20.sdp), child: _buildVisitControls()),
                      SizedBox(height: 16.sdp),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildVisitTab(
                              items: _viewModel.assignedVisits,
                              onRetry: _viewModel.loadAssignedVisits,
                              onReset: () async { _viewModel.resetAssignedFilters(); await _viewModel.loadAssignedVisits(); },
                              emptyTitle: 'No assigned visits found for today',
                              emptyMessage: 'Add new visits from the "Add New Visit" screen.',
                              errorTitle: 'Unable to load assigned visits',
                              cardBuilder: (item) => AssignedVisitCard(visit: item, viewModel: _viewModel, dateTimeFormat: _dateTimeFormat),
                            ),
                            _buildVisitTab(
                              items: _viewModel.onHoldVisits,
                              onRetry: _viewModel.loadOnHoldVisits,
                              onReset: () async { _viewModel.resetOnHoldFilters(); await _viewModel.loadOnHoldVisits(); },
                              emptyTitle: 'No on-hold clients found',
                              emptyMessage: 'Change the scope filter or refresh the list.',
                              errorTitle: 'Unable to load on-hold clients',
                              cardBuilder: (item) => OnHoldVisitCard(visit: item, viewModel: _viewModel, dateTimeFormat: _dateTimeFormat),
                            ),
                            _buildVisitTab(
                              items: _viewModel.completedVisits,
                              onRetry: _viewModel.loadCompletedVisits,
                              onReset: () async { _viewModel.resetCompletedFilters(); await _viewModel.loadCompletedVisits(); },
                              emptyTitle: 'No completed tasks found',
                              emptyMessage: 'Try changing the date range filter.',
                              errorTitle: 'Unable to load completed tasks',
                              cardBuilder: (item) => CompletedVisitCard(visit: item, dateTimeFormat: _dateTimeFormat),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BoxDecoration _sheetDecoration(ThemeData theme) => BoxDecoration(
    color: theme.cardTheme.color ?? theme.colorScheme.surface,
    borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
    boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 24.sdp, offset: Offset(0, -4.sdp))],
  );

  Widget _buildTabBar(ThemeData theme) {
    final color = switch (_viewModel.selectedVisitTabIndex) { 0 => Colors.blue, 1 => Colors.orange, 2 => Colors.green, _ => theme.colorScheme.primary };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.sdp, horizontal: 20.sdp),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18.sdp),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(4.sdp),
          indicator: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14.sdp),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8.sdp, offset: const Offset(0, 2))],
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'Assigned (${_viewModel.assignedVisits.length})'),
            Tab(text: 'On-Hold (${_viewModel.onHoldVisits.length})'),
            Tab(text: 'Completed (${_viewModel.completedVisits.length})'),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitControls() {
    return switch (_viewModel.selectedVisitTabIndex) {
      0 => Column(
          children: [
            VisitSearchBar(
              controller: _assignedSearchController,
              hintText: 'Search client, purpose, address',
              onSubmitted: (val) { _viewModel.setAssignedSearchQuery(val); _viewModel.loadAssignedVisits(); },
              hasActiveFilters: _hasAssignedFilters,
            ),
            if (_hasAssignedFilters) _buildAssignedFilterChips(),
          ],
        ),
      1 => Column(
          children: [
            VisitSearchBar(
              controller: _onHoldSearchController,
              hintText: 'Search client, purpose, address',
              onChanged: _viewModel.setOnHoldSearchQuery,
              onFilterPressed: _showOnHoldFilterSheet,
              hasActiveFilters: _viewModel.onHoldScope != 'all',
            ),
            if (_viewModel.onHoldScope != 'all') 
              Padding(
                padding: EdgeInsets.only(top: 12.sdp),
                child: ActiveFilterChip(label: 'Scope: ${_viewModel.onHoldScope}', onDeleted: () { _viewModel.setOnHoldScope('all'); _viewModel.loadOnHoldVisits(); }),
              ),
          ],
        ),
      2 => Column(
          children: [
            VisitSearchBar(
              controller: _completedSearchController,
              hintText: 'Search client, purpose, address',
              onChanged: _viewModel.setCompletedSearchQuery,
              onFilterPressed: _showCompletedFilterSheet,
              hasActiveFilters: _hasCompletedFilters,
            ),
            if (_hasCompletedFilters)
              Padding(
                padding: EdgeInsets.only(top: 12.sdp),
                child: ActiveFilterChip(
                  label: 'Date: ${formatVisitSlot(_viewModel.completedStartDate, _viewModel.completedEndDate, _dateFormat)}',
                  onDeleted: () { _viewModel.updateCompletedFilters(clearDates: true); _viewModel.loadCompletedVisits(); },
                ),
              ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  bool get _hasAssignedFilters => _viewModel.assignedFeName.isNotEmpty || _viewModel.assignedEmployeeId.isNotEmpty || _viewModel.assignedStatus != 'all' || _viewModel.assignedStartDate != null || _viewModel.assignedEndDate != null;
  bool get _hasCompletedFilters => _viewModel.completedStartDate != null || _viewModel.completedEndDate != null;

  Widget _buildAssignedFilterChips() {
    return Padding(
      padding: EdgeInsets.only(top: 12.sdp),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_viewModel.assignedFeName.isNotEmpty) ActiveFilterChip(label: 'FE: ${_viewModel.assignedFeName}', onDeleted: () { _viewModel.updateAssignedFilters(feName: ''); _viewModel.loadAssignedVisits(); }),
            if (_viewModel.assignedEmployeeId.isNotEmpty) ActiveFilterChip(label: 'Emp: ${_viewModel.assignedEmployeeId}', onDeleted: () { _viewModel.updateAssignedFilters(employeeId: ''); _viewModel.loadAssignedVisits(); }),
            if (_viewModel.assignedStatus != 'all') ActiveFilterChip(label: 'Status: ${_viewModel.assignedStatus}', onDeleted: () { _viewModel.updateAssignedFilters(status: 'all'); _viewModel.loadAssignedVisits(); }),
            if (_viewModel.assignedStartDate != null || _viewModel.assignedEndDate != null) ActiveFilterChip(label: 'Date: ${formatVisitSlot(_viewModel.assignedStartDate, _viewModel.assignedEndDate, _dateFormat)}', onDeleted: () { _viewModel.updateAssignedFilters(clearDates: true); _viewModel.loadAssignedVisits(); }),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTab<T>({required List<T> items, required Future<void> Function() onRetry, required VoidCallback onReset, required String emptyTitle, required String emptyMessage, required String errorTitle, required Widget Function(T) cardBuilder}) {
    if (_viewModel.isVisitDetailsLoading && items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_viewModel.visitDetailsErrorMessage != null && items.isEmpty) return VisitStateView(title: errorTitle, message: _viewModel.visitDetailsErrorMessage!, actionLabel: 'Retry', onPressed: onRetry);
    if (items.isEmpty) return VisitStateView(title: emptyTitle, message: emptyMessage, actionLabel: 'Clear Filters', onPressed: () async => onReset());

    return RefreshIndicator(
      onRefresh: _viewModel.initializeVisitDetails,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.sdp, 0, 20.sdp, 28.sdp),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.sdp),
        itemBuilder: (_, index) => cardBuilder(items[index]),
      ),
    );
  }

  // --- Filter Sheets ---

  // Future<void> _showAssignedFilterSheet() async {
  //   final feController = TextEditingController(text: _viewModel.assignedFeName);
  //   final empController = TextEditingController(text: _viewModel.assignedEmployeeId);
  //   DateTime? start = _viewModel.assignedStartDate;
  //   DateTime? end = _viewModel.assignedEndDate;
  //   String status = _viewModel.assignedStatus;
  //
  //   await _showFilterModal(
  //     title: 'Assigned Filters',
  //     onClear: () { _viewModel.resetAssignedFilters(); _viewModel.loadAssignedVisits(); },
  //     onApply: () { _viewModel.updateAssignedFilters(startDate: start, endDate: end, feName: feController.text.trim(), employeeId: empController.text.trim(), status: status); _viewModel.loadAssignedVisits(); },
  //     builder: (context, setModalState) => [
  //       _buildTextField(feController, 'FE Name'),
  //       SizedBox(height: 12.sdp),
  //       _buildTextField(empController, 'Employee ID'),
  //       SizedBox(height: 12.sdp),
  //       _buildDropdown(status, 'Status', const [
  //         DropdownMenuItem(value: 'all', child: Text('All Statuses')),
  //         DropdownMenuItem(value: 'pending', child: Text('Pending')),
  //         DropdownMenuItem(value: 'completed', child: Text('Completed')),
  //         DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
  //       ], (val) => setModalState(() => status = val!)),
  //       SizedBox(height: 12.sdp),
  //       _buildDateRangePicker(start, end, (s, e) => setModalState(() { start = s; end = e; })),
  //     ],
  //   );
  //
  //   feController.dispose();
  //   empController.dispose();
  // }

  Future<void> _showOnHoldFilterSheet() async {
    String scope = _viewModel.onHoldScope;
    await _showFilterModal(
      title: 'On-Hold Filters',
      onClear: () { _viewModel.resetOnHoldFilters(); _viewModel.loadOnHoldVisits(); },
      onApply: () { _viewModel.setOnHoldScope(scope); _viewModel.loadOnHoldVisits(); },
      builder: (context, setModalState) => [
        _buildDropdown(scope, 'Scope', const [
          DropdownMenuItem(value: 'all', child: Text('All')),
          DropdownMenuItem(value: 'today', child: Text('Today')),
        ], (val) => setModalState(() => scope = val!)),
      ],
    );
  }

  Future<void> _showCompletedFilterSheet() async {
    DateTime? start = _viewModel.completedStartDate;
    DateTime? end = _viewModel.completedEndDate;
    await _showFilterModal(
      title: 'Completed Filters',
      onClear: () { _viewModel.resetCompletedFilters(); _viewModel.loadCompletedVisits(); },
      onApply: () { _viewModel.updateCompletedFilters(startDate: start, endDate: end); _viewModel.loadCompletedVisits(); },
      builder: (context, setModalState) => [_buildDateRangePicker(start, end, (s, e) => setModalState(() { start = s; end = e; }))],
    );
  }

  // --- Helper UI Components ---

  Future<void> _showFilterModal({required String title, required VoidCallback onClear, required VoidCallback onApply, required List<Widget> Function(BuildContext, StateSetter) builder}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FilterBottomSheetLayout(
          title: title,
          onClear: () { onClear(); Navigator.pop(context); },
          onApply: () { onApply(); Navigator.pop(context); },
          children: builder(context, setModalState),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, String label, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.sdp), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)))),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateRangePicker(DateTime? start, DateTime? end, Function(DateTime?, DateTime?) onChanged) {
    return Row(
      children: [
        Expanded(child: DateField(label: 'Start Date', value: start, formatter: _dateFormat, onTap: () async { final d = await _pickDate(start); if (d != null) onChanged(d, end); })),
        SizedBox(width: 12.sdp),
        Expanded(child: DateField(label: 'End Date', value: end, formatter: _dateFormat, onTap: () async { final d = await _pickDate(end); if (d != null) onChanged(start, d); })),
      ],
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));

  void _syncControllers() {
    _syncController(_assignedSearchController, _viewModel.assignedSearchQuery);
    _syncController(_onHoldSearchController, _viewModel.onHoldSearchQuery);
    _syncController(_completedSearchController, _viewModel.completedSearchQuery);
    if (_tabController.index != _viewModel.selectedVisitTabIndex) _tabController.index = _viewModel.selectedVisitTabIndex;
  }

  void _syncController(TextEditingController c, String val) {
    if (c.text != val) {
      c.value = TextEditingValue(text: val, selection: TextSelection.collapsed(offset: val.length));
    }
  }
}
