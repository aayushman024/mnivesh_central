import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../Utils/CallynDateHelper.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/callynAnalytics_viewModel.dart';

// ─── Filter Tabs ──────────────────────────────────────────────────────────────

/// Horizontally scrollable row of filter chips (Today, This Week, etc.)
/// plus date-picker and range-picker chips.
class AnalyticsFilterTabs extends StatefulWidget {
  const AnalyticsFilterTabs({Key? key}) : super(key: key);

  @override
  State<AnalyticsFilterTabs> createState() => _AnalyticsFilterTabsState();
}

class _AnalyticsFilterTabsState extends State<AnalyticsFilterTabs> {
  DateTime?      _customDate;
  DateTimeRange? _customRange;
  // 'date' | 'range' | null — tracks which custom picker is active.
  String?        _customActive;

  // ── Async pickers — capture vm via context.read BEFORE the await gap ──────

  Future<void> _pickDate() async {
    // Read vm synchronously before any await to avoid async context warnings.
    final vm  = context.read<CallLogAnalyticsViewModel>();
    final now = DateTime.now();

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

  Future<void> _pickRange() async {
    final vm  = context.read<CallLogAnalyticsViewModel>();
    final now = DateTime.now();

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
    // context.select: widget rebuilds ONLY when selectedFilter or filterLabels
    // change — not on isLoading, errorMessage, analyticsData, etc.
    final selectedFilter = context.select(
          (CallLogAnalyticsViewModel v) => v.selectedFilter,
    );
    final filterLabels = context.select(
          (CallLogAnalyticsViewModel v) => v.filterLabels,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 54.sdp,
      child: ListView(
        padding:         EdgeInsets.symmetric(horizontal: 16.sdp),
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        children: [
          // ── Preset filter chips ─────────────────────────────────────────
          ...AnalyticsFilter.values.map((filter) {
            final isSelected =
                selectedFilter == filter && _customActive == null;

            return Padding(
              padding: EdgeInsets.only(right: 8.sdp),
              child: GestureDetector(
                // context.read in a tap callback — correct pattern.
                onTap: () {
                  setState(() => _customActive = null);
                  context.read<CallLogAnalyticsViewModel>().setFilter(filter);
                },
                child: _FilterChip(
                  label:      filterLabels[filter]!,
                  hint:       filterDateHint(filter),
                  isSelected: isSelected,
                  cs:         colorScheme,
                ),
              ),
            );
          }),

          // ── Custom date picker ──────────────────────────────────────────
          _DatePickerChip(
            icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
            label: _customActive == 'date' && _customDate != null
                ? fmtDate(_customDate!)
                : 'Select Date',
            isActive: _customActive == 'date',
            cs:       colorScheme,
            onTap:    _pickDate,
          ),
          SizedBox(width: 8.sdp),

          // ── Custom date range picker ────────────────────────────────────
          _DatePickerChip(
            icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
            label: _customActive == 'range' && _customRange != null
                ? '${fmtShort(_customRange!.start)} – ${fmtShort(_customRange!.end)}'
                : 'Select Range',
            isActive: _customActive == 'range',
            cs:       colorScheme,
            onTap:    _pickRange,
          ),
        ],
      ),
    );
  }
}

// ─── _FilterChip ──────────────────────────────────────────────────────────────

/// A single preset-filter chip (e.g. "Today", "This Week").
class _FilterChip extends StatelessWidget {
  final String      label;
  final String      hint;
  final bool        isSelected;
  final ColorScheme cs;

  const _FilterChip({
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve:    Curves.easeOutCubic,
      padding:  EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withOpacity(0.88)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(
          color: isSelected
              ? cs.primary.withOpacity(0.80)
              : cs.outlineVariant.withOpacity(0.20),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color:      cs.primary.withOpacity(0.16),
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
            label,
            style: TextStyle(
              fontSize:      13.ssp,
              fontWeight:    FontWeight.w600,
              color:         isSelected ? cs.onPrimary : cs.onSurface,
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
                color: isSelected
                    ? cs.onPrimary.withOpacity(0.68)
                    : cs.onSurfaceVariant.withOpacity(0.58),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _DatePickerChip ──────────────────────────────────────────────────────────

/// A chip that opens a date or date-range picker when tapped.
class _DatePickerChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String           label;
  final bool             isActive;
  final ColorScheme      cs;
  final VoidCallback     onTap;

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