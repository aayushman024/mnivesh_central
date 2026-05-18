import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/API/operations_apiService.dart';
import 'package:mnivesh_central/Models/investwell_report_models.dart';
import 'package:mnivesh_central/Models/mftrans_models.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:mnivesh_central/Utils/Dimensions.dart';
import 'package:mnivesh_central/ViewModels/investwellReport_viewModel.dart';
import 'package:mnivesh_central/Views/Widgets/ModuleAppBar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shimmer/shimmer.dart';

class InvestwellReportScreen extends ConsumerWidget {
  const InvestwellReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(investwellReportViewModelProvider);
    final notifier = ref.read(investwellReportViewModelProvider.notifier);

    return Scaffold(
      appBar: const ModuleAppBar(title: 'Investwell Reports'),
      body: Container(
        width: double.infinity,
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(16.sdp, 18.sdp, 16.sdp, 16.sdp),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32.sdp),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 24.sdp,
                      offset: Offset(0, -4.sdp),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 8.sdp),
                    _buildFilters(context, state, notifier, colorScheme),
                    SizedBox(height: 18.sdp),
                    Expanded(child: _buildBody(state, colorScheme)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    InvestwellReportState state,
    InvestwellReportViewModel notifier,
    ColorScheme colorScheme,
  ) {
    final bool shouldBeExpanded = state.isFiltersExpanded || state.reportFile == null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: shouldBeExpanded
            ? _buildExpandedFilters(context, state, notifier, colorScheme)
            : _buildCollapsedFilters(state, notifier, colorScheme),
      ),
    );
  }

  Widget _buildExpandedFilters(
    BuildContext context,
    InvestwellReportState state,
    InvestwellReportViewModel notifier,
    ColorScheme colorScheme,
  ) {
    return Column(
      key: const ValueKey('expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Investor Name',
              style: AppTextStyle.normal
                  .small(colorScheme.onSurface.withValues(alpha: 0.6))
                  .copyWith(fontSize: 13.ssp),
            ),
            if (state.reportFile != null)
              GestureDetector(
                onTap: notifier.toggleFilters,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.sdp, vertical: 4.sdp),
                  child: Container(
                    padding: EdgeInsets.all(8.sdp),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.sdp)
                    ),
                    child: Row(
                      children: [
                        Text("Collapse", style: AppTextStyle.normal.custom(11.ssp, colorScheme.primary),),
                        PhosphorIcon(
                          PhosphorIcons.caretUp(PhosphorIconsStyle.bold),
                          size: 16.sdp,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.sdp),
        _InvestorAutocomplete(
          hint: 'Search investor by name...',
          skipSearchText: state.selectedInvestor?.name,
          displayString: (o) => o.name,
          onInitController: (_) {},
          searchFunction: (query) =>
              OperationsApiService.searchInvestors(name: query, searchAll: true),
          onSelected: (investor) {
            notifier.setSelectedInvestor(investor);
          },
          onCleared: () {
            notifier.setSelectedInvestor(null);
          },
        ),
        SizedBox(height: 8.sdp),
        if (state.selectedInvestor != null)
          Text(
            'PAN: ${state.selectedInvestor!.pan}',
            style: AppTextStyle.normal.small(
              colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        SizedBox(height: 14.sdp),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<InvestwellReportType>(
                initialValue: state.selectedType,
                decoration: _inputDecoration('Report Type', colorScheme),
                items: const [
                  DropdownMenuItem(
                    value: InvestwellReportType.capitalGain,
                    child: Text('Capital Gain'),
                  ),
                  DropdownMenuItem(
                    value: InvestwellReportType.portfolio,
                    child: Text('Portfolio'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  notifier.setSelectedType(value);
                },
              ),
            ),
            SizedBox(width: 12.sdp),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: state.selectedType == InvestwellReportType.capitalGain
                    ? state.selectedYear
                    : null,
                decoration: _inputDecoration('Year', colorScheme),
                items: state.years
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: state.selectedType == InvestwellReportType.capitalGain
                    ? (year) => notifier.setSelectedYear(year)
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.sdp),
        SizedBox(
          width: double.infinity,
          height: 50.sdp,
          child: ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () => notifier.fetchReport(
                      onError: (error) => SnackbarService.showError(error),
                    ),
            icon: state.isLoading
                ? SizedBox(
                    width: 18.sdp,
                    height: 18.sdp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : PhosphorIcon(
                    PhosphorIcons.magnifyingGlass(),
                    size: 16.sdp,
                    color: Colors.white,
                  ),
            label: Text(
              state.isLoading ? 'Fetching...' : 'Fetch Report',
              style: AppTextStyle.extraBold
                  .normal(Colors.white)
                  .copyWith(fontSize: 14.ssp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.sdp),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedFilters(
    InvestwellReportState state,
    InvestwellReportViewModel notifier,
    ColorScheme colorScheme,
  ) {
    String typeString = state.selectedType == InvestwellReportType.capitalGain ? 'Capital Gain' : 'Portfolio';
    String yearString = state.selectedYear?.toString() ?? '';
    
    return GestureDetector(
      onTap: notifier.toggleFilters,
      child: Container(
        key: const ValueKey('collapsed'),
        padding: EdgeInsets.symmetric(vertical: 10.sdp, horizontal: 12.sdp),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withAlpha(20),
              blurRadius: 8.sdp,
              spreadRadius: 1.sdp
            )
          ]
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${state.selectedInvestor?.name ?? "Unknown"} • $typeString${yearString.isNotEmpty ? ' • $yearString' : ''}',
                style: AppTextStyle.bold.normal(colorScheme.onSurface).copyWith(fontSize: 13.ssp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.sdp),
            Container(
                padding: EdgeInsets.all(6.sdp),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                  size: 16.sdp,
                  color: colorScheme.primary,
                ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.sdp),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.sdp),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.sdp),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
      ),
    );
  }

  Widget _buildBody(InvestwellReportState state, ColorScheme colorScheme) {
    if (state.isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.sdp),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14.sdp),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Shimmer.fromColors(
          baseColor: colorScheme.onSurface.withValues(alpha: 0.1),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 180.sdp,
                height: 24.sdp,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.sdp)),
              ),
              SizedBox(height: 32.sdp),
              ...List.generate(5, (index) => Padding(
                padding: EdgeInsets.only(bottom: 16.sdp),
                child: Container(
                  width: index == 4 ? 200.sdp : double.infinity,
                  height: 12.sdp,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.sdp)),
                ),
              )),
              SizedBox(height: 32.sdp),
              ...List.generate(4, (index) => Padding(
                padding: EdgeInsets.only(bottom: 16.sdp),
                child: Container(
                  width: index == 3 ? 150.sdp : double.infinity,
                  height: 12.sdp,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.sdp)),
                ),
              )),
            ],
          ),
        ),
      );
    }

    if (state.errorText != null) {
      return Center(
        child: Text(
          state.errorText!,
          textAlign: TextAlign.center,
          style: AppTextStyle.normal.normal(colorScheme.error),
        ),
      );
    }

    if (state.reportFile == null) {
      return Center(
        child: Text(
          'Search an investor, choose report type, and fetch to view report.',
          textAlign: TextAlign.center,
          style: AppTextStyle.normal
              .normal(colorScheme.onSurface.withValues(alpha: 0.6))
              .copyWith(fontSize: 14.ssp),
        ),
      );
    }

    return PdfViewer.data(
      state.reportFile!.bytes,
      sourceName: '${state.reportFile!.fileName}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class _InvestorAutocomplete extends StatefulWidget {
  final String hint;
  final String? skipSearchText;
  final String Function(InvestorModel) displayString;
  final void Function(TextEditingController) onInitController;
  final Future<List<InvestorModel>> Function(String) searchFunction;
  final void Function(InvestorModel) onSelected;
  final VoidCallback onCleared;

  const _InvestorAutocomplete({
    required this.hint,
    this.skipSearchText,
    required this.displayString,
    required this.onInitController,
    required this.searchFunction,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  State<_InvestorAutocomplete> createState() => _InvestorAutocompleteState();
}

class _InvestorAutocompleteState extends State<_InvestorAutocomplete> {
  Timer? _debounceTimer;
  Completer<List<InvestorModel>>? _pendingCompleter;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _completePending(const []);
    super.dispose();
  }

  Future<List<InvestorModel>> _debouncedSearch(String query) {
    _debounceTimer?.cancel();
    _completePending(const []);

    final completer = Completer<List<InvestorModel>>();
    _pendingCompleter = completer;
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) {
        _completePending(const []);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await widget.searchFunction(query);
        if (!completer.isCompleted) {
          completer.complete(results);
        }
      } catch (_) {
        if (!completer.isCompleted) {
          completer.complete(const []);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        if (identical(_pendingCompleter, completer)) {
          _pendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  void _completePending(List<InvestorModel> fallback) {
    final pending = _pendingCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete(fallback);
    }
    _pendingCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Autocomplete<InvestorModel>(
      optionsBuilder: (tev) async {
        final query = tev.text.trim();
        if (query.isEmpty || query.length < 2) return const [];
        if (widget.skipSearchText != null && query == widget.skipSearchText) {
          return const [];
        }
        return _debouncedSearch(query);
      },
      displayStringForOption: widget.displayString,
      onSelected: widget.onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
        widget.onInitController(ctrl);
        ctrl.addListener(() => setState(() {}));
        return TextFormField(
          controller: ctrl,
          focusNode: focus,
          style: AppTextStyle.normal.normal(colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyle.normal
                .normal(colorScheme.onSurface.withValues(alpha: 0.4))
                .copyWith(fontSize: 14.ssp),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.sdp,
              vertical: 16.sdp,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            suffixIcon: _isLoading
                ? Padding(
                    padding: EdgeInsets.all(12.sdp),
                    child: SizedBox(
                      width: 16.sdp,
                      height: 16.sdp,
                      child: const CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : (ctrl.text.isNotEmpty)
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        ctrl.clear();
                      });
                      widget.onCleared();
                    },
                    icon: PhosphorIcon(PhosphorIcons.x(), size: 14.ssp),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
            ),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSel, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 50,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(16.sdp),
            color: theme.cardColor,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 420.sdp,
                maxWidth: MediaQuery.of(ctx).size.width - 48.sdp,
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.sdp),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1.sdp,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                itemBuilder: (ctx, i) {
                  final option = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSel(option),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.sdp,
                        vertical: 14.sdp,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.name,
                            style: AppTextStyle.extraBold
                                .small(colorScheme.onSurface)
                                .copyWith(
                                  fontSize: 14.ssp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 4.sdp),
                          Text(
                            'PAN: ${option.pan} - Head: ${option.familyHead}',
                            style: AppTextStyle.normal
                                .small(colorScheme.onSurface.withValues(alpha: 0.6))
                                .copyWith(fontSize: 12.ssp),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
