// lib/Views/MFTransaction/Widgets/form_components.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';

// ─────────────────────────────────────────────
// Text Input
// ─────────────────────────────────────────────

class MfTextInput extends StatelessWidget {
  final String label;
  final bool isNumber;
  final int? maxLength;
  final TextEditingController? controller;
  final void Function(String)? onChanged;

  const MfTextInput({
    super.key,
    required this.label,
    this.isNumber = false,
    this.maxLength,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLength: maxLength,
      style: AppTextStyle.normal
          .normal(colorScheme.onSurface)
          .copyWith(fontSize: 14.ssp, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyle.normal
            .small(colorScheme.onSurface.withOpacity(0.6))
            .copyWith(fontSize: 13.ssp),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.sdp,
          vertical: 16.sdp,
        ),
        filled: true,
        counterText: '',
        fillColor: theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom-Sheet Dropdown  (improved design)
// ─────────────────────────────────────────────

class MfDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const MfDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String get _safeValue => items.contains(value) ? value : items.first;

  void _showPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.sdp)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.sdp),
                width: 40.sdp,
                height: 4.sdp,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2.sdp),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.sdp,
                  vertical: 16.sdp,
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyle.extraBold
                          .normal(colorScheme.onSurface)
                          .copyWith(fontSize: 16.ssp),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
              // Options
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8.sdp),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 20.sdp,
                    endIndent: 20.sdp,
                    color: colorScheme.onSurface.withOpacity(0.05),
                  ),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final isSelected = item == _safeValue;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        onChanged(item);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.sdp,
                          vertical: 14.sdp,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyle.normal
                                    .normal(
                                      isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    )
                                    .copyWith(
                                      fontSize: 14.ssp,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: colorScheme.primary,
                                size: 20.sdp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8.sdp),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16.sdp),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyle.normal
                        .small(colorScheme.onSurface.withOpacity(0.55))
                        .copyWith(fontSize: 11.ssp),
                  ),
                  SizedBox(height: 2.sdp),
                  Text(
                    _safeValue,
                    style: AppTextStyle.normal
                        .normal(colorScheme.onSurface)
                        .copyWith(
                          fontSize: 14.ssp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 20.sdp,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Date Picker (Replacing the old predefined date array)
// ─────────────────────────────────────────────

class MfDatePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const MfDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      // formatting date as dd/mm/yyyy
      final String formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      onChanged(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16.sdp),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyle.normal
                        .small(colorScheme.onSurface.withOpacity(0.55))
                        .copyWith(fontSize: 11.ssp),
                  ),
                  SizedBox(height: 2.sdp),
                  Text(
                    value.isEmpty ? 'Select Date' : value,
                    style: AppTextStyle.normal
                        .normal(colorScheme.onSurface)
                        .copyWith(
                          fontSize: 14.ssp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 20.sdp,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single Select Chips (Horizontal Scroll)
// ─────────────────────────────────────────────

class MfSingleSelectChips extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const MfSingleSelectChips({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String get _safeValue => items.contains(value) ? value : items.first;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.sdp),
          child: Text(
            label,
            style: AppTextStyle.normal
                .small(colorScheme.onSurface.withOpacity(0.55))
                .copyWith(fontSize: 12.ssp),
          ),
        ),
        SizedBox(height: 8.sdp),
        // single select chips wrapped in horizontal scroll to prevent overflow on narrow screens
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = item == _safeValue;
              return Padding(
                padding: EdgeInsets.only(right: 12.sdp),
                child: ChoiceChip(
                  label: Text(item),
                  labelStyle: AppTextStyle.normal
                      .normal(
                        isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      )
                      .copyWith(
                        fontSize: 13.ssp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                  selected: isSelected,
                  showCheckmark: true,
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sdp),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) onChanged(item);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Modern red-accented delete confirmation dialog
Future<bool?> showDeleteConfirmationDialog(
  BuildContext context,
  String formName,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.sdp),
      ),
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
            color: colorScheme.error,
            size: 24.sdp,
          ),
          SizedBox(width: 8.sdp),
          Text(
            'Delete Draft',
            style: AppTextStyle.extraBold
                .normal(colorScheme.error)
                .copyWith(fontSize: 16.ssp),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this "$formName"? This action cannot be undone.',
        style: AppTextStyle.normal
            .normal(colorScheme.onSurface)
            .copyWith(fontSize: 14.ssp),
      ),
      actionsPadding: EdgeInsets.fromLTRB(16.sdp, 0, 16.sdp, 16.sdp),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: AppTextStyle.normal.normal(colorScheme.primary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.sdp),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 10.sdp),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Delete',
            style: AppTextStyle.extraBold.normal(colorScheme.onError),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// Section Spacer
// ─────────────────────────────────────────────

class FormSpacer extends StatelessWidget {
  const FormSpacer({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: 16.sdp);
}
