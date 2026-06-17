import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class VisitStateView extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const VisitStateView({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sdp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.extraBold.custom(
                18.ssp,
                theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10.sdp),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.normal.custom(
                13.ssp,
                theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 18.sdp),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const ActiveFilterChip({super.key, required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(right: 8.sdp),
      child: InputChip(
        label: Text(label),
        labelStyle: AppTextStyle.normal.custom(
          11.ssp,
          colorScheme.onPrimaryContainer,
        ),
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
        deleteIcon: Icon(PhosphorIconsRegular.xCircle, size: 16.sdp),
        deleteIconColor: colorScheme.onPrimaryContainer,
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.sdp),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 4.sdp, vertical: 0),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.sdp),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10.sdp,
            offset: Offset(0, 4.sdp),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sdp),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.sdp),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.sdp),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 12.sdp),
            suffixIcon: Icon(PhosphorIconsRegular.calendar, size: 20.sdp, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          ),
          child: Text(
            value == null ? 'Select date' : formatter.format(value!),
            style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class VisitSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;

  const VisitSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.onFilterPressed,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18.sdp),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12.sdp,
                  offset: Offset(0, 4.sdp),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyle.normal.custom(12.ssp, Colors.grey),
                prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20.sdp),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onSubmitted?.call('');
                          onChanged?.call('');
                        },
                        icon: Icon(PhosphorIconsRegular.x, size: 18.sdp),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.sdp),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.sdp),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.sdp),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                isDense: true,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.sdp),
        Badge(
          isLabelVisible: hasActiveFilters,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.sdp),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12.sdp,
                  offset: Offset(0, 4.sdp),
                ),
              ],
            ),
            child: OutlinedButton.icon(
              onPressed: onFilterPressed,
              icon: Icon(PhosphorIconsRegular.sliders, size: 20.sdp),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.sdp,
                  vertical: 12.sdp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.sdp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FilterBottomSheetLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const FilterBottomSheetLayout({
    super.key,
    required this.title,
    required this.children,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24.sdp,
            offset: Offset(0, -4.sdp),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24.sdp,
        24.sdp,
        24.sdp,
        MediaQuery.of(context).viewInsets.bottom + 24.sdp,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.sdp,
              height: 4.sdp,
              margin: EdgeInsets.only(bottom: 24.sdp),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.sdp),
              ),
            ),
          ),
          Text(
            title,
            style: AppTextStyle.extraBold.custom(
              20.ssp,
              theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24.sdp),
          ...children,
          SizedBox(height: 28.sdp),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.sdp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.sdp),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text('Clear All', style: AppTextStyle.bold.custom(14.ssp, theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
              ),
              SizedBox(width: 12.sdp),
              Expanded(
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.sdp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.sdp),
                    ),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  child: Text('Apply Filters', style: AppTextStyle.bold.custom(14.ssp, Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String formatVisitSlot(DateTime? start, DateTime? end, DateFormat formatter, {bool canGoAnytime = false}) {
  if (canGoAnytime) {
    return 'Anytime';
  }
  if (start == null && end == null) {
    return '-';
  }
  
  final localStart = start?.toLocal();
  final localEnd = end?.toLocal();

  if (localStart != null && localEnd != null) {
    final startText = formatter.format(localStart);
    final endText = DateFormat('hh:mm a').format(localEnd);
    return '$startText - $endText';
  }
  return formatter.format(localStart ?? localEnd!);
}
