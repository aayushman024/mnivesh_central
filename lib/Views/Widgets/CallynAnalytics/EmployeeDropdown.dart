import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/callynAnalytics_viewModel.dart';

/// Dropdown for selecting a specific employee or viewing all employees.
class EmployeeFilterDropdown extends StatelessWidget {
  const EmployeeFilterDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Two granular selectors instead of context.watch — this widget now only
    // rebuilds when searchName or employees change, not on every VM change
    // (e.g. isLoading, analyticsData, selectedFilter).
    final searchName = context.select(
          (CallLogAnalyticsViewModel v) => v.searchName,
    );
    final employees = context.select(
          (CallLogAnalyticsViewModel v) => v.employees,
    );

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin:  EdgeInsets.symmetric(horizontal: 16.sdp),
      padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 2.sdp),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:      searchName,
          isExpanded: true,
          hint: Text(
            'All Employees',
            style: TextStyle(
              fontSize:   13.ssp,
              fontWeight: FontWeight.w500,
              color:      cs.onSurfaceVariant,
            ),
          ),
          icon: PhosphorIcon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
            size:  14.sdp,
            color: cs.onSurfaceVariant,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Employees',
                style: TextStyle(
                  fontSize:   13.ssp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...employees.map((e) => DropdownMenuItem<String>(
              value: e.username,
              child: Text(
                e.username,
                style: TextStyle(
                  fontSize:   13.ssp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
          ],
          // context.read in a callback — correct Provider pattern, not during build.
          onChanged: (val) =>
              context.read<CallLogAnalyticsViewModel>().setSearchName(val),
        ),
      ),
    );
  }
}