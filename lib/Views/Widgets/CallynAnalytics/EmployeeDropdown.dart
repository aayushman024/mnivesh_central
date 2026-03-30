import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/callynAnalytics_viewModel.dart';

/// Dropdown for selecting a specific employee or viewing all employees.
class EmployeeFilterDropdown extends StatelessWidget {
  const EmployeeFilterDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchName = context.select(
          (CallLogAnalyticsViewModel v) => v.searchName,
    );
    final employees = context.select(
          (CallLogAnalyticsViewModel v) => v.employees,
    );

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sdp),
      padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.sdp),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 👤 Icon for visual hierarchy
          PhosphorIcon(
            PhosphorIcons.users(PhosphorIconsStyle.bold),
            size: 16.sdp,
            color: cs.primary.withOpacity(0.9),
          ),

          SizedBox(width: 10.sdp),

          // Dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: searchName,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12.sdp),
                hint: Text(
                  'All Employees',
                  style: AppTextStyle.normal.custom(
                    13.ssp,
                    cs.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),

                icon: PhosphorIcon(
                  PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                  size: 14.sdp,
                  color: cs.onSurfaceVariant,
                ),

                style: AppTextStyle.normal.custom(
                  13.ssp,
                  cs.onSurface,
                ),

                dropdownColor: cs.surfaceContainerHigh,

                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'All Employees',
                      style: AppTextStyle.normal.custom(13.ssp),
                    ),
                  ),
                  ...employees.map(
                        (e) => DropdownMenuItem<String>(
                      value: e.username,
                      child: Text(
                        e.username,
                        style: AppTextStyle.normal.custom(13.ssp),
                      ),
                    ),
                  ),
                ],

                onChanged: (val) => context
                    .read<CallLogAnalyticsViewModel>()
                    .setSearchName(val),
              ),
            ),
          ),
        ],
      ),
    );
  }
}