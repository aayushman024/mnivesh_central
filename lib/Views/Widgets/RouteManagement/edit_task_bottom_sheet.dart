import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';

class EditTaskBottomSheet extends StatefulWidget {
  final dynamic visit; // Can be AssignedVisitDetails or OnHoldVisitDetails
  final RouteOptimizationViewModel viewModel;

  const EditTaskBottomSheet({
    super.key,
    required this.visit,
    required this.viewModel,
  });

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _visitAddressController;
  late final TextEditingController _purposeController;

  String? _selectedFeId;
  late int _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  List<double>? _coordinates;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    
    // Determine initial values based on visit type
    final start = v is AssignedVisitDetails ? v.slotStart : (v as OnHoldVisitDetails).availabilityStart;
    final end = v is AssignedVisitDetails ? v.slotEnd : (v as OnHoldVisitDetails).availabilityEnd;
    final feId = v is AssignedVisitDetails ? v.feId : (v as OnHoldVisitDetails).assignedFeId;
    final priority = int.tryParse(v.priority.toString()) ?? 3;

    _visitAddressController = TextEditingController(text: v.visitingAddress);
    _purposeController = TextEditingController(text: v.purposeOfVisit);
    
    _selectedFeId = feId;
    _selectedPriority = priority;
    _selectedDate = start ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(_selectedDate);
    _endTime = TimeOfDay.fromDateTime(end ?? _selectedDate.add(const Duration(hours: 1)));
    
    // Trigger FE availability check once initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCoordinatesAndFEs();
    });
  }

  Future<void> _fetchCoordinatesAndFEs() async {
    if (_visitAddressController.text.isNotEmpty) {
      await widget.viewModel.fetchCoordinatesForAddress(_visitAddressController.text);
      // Synchronize internal state with viewmodel
      setState(() {
        _coordinates = widget.viewModel.selectedCoordinates;
      });
    }
  }

  @override
  void dispose() {
    _visitAddressController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getOriginalData() {
    final v = widget.visit;
    final start = v is AssignedVisitDetails ? v.slotStart : (v as OnHoldVisitDetails).availabilityStart;
    final end = v is AssignedVisitDetails ? v.slotEnd : (v as OnHoldVisitDetails).availabilityEnd;
    final feId = v is AssignedVisitDetails ? v.feId : (v as OnHoldVisitDetails).assignedFeId;

    return {
      'visitingAddress': v.visitingAddress,
      'purposeOfVisit': v.purposeOfVisit,
      'priority': int.tryParse(v.priority.toString()) ?? 3,
      'availabilityStart': start?.toIso8601String(),
      'availabilityEnd': end?.toIso8601String(),
      'assignedFE': feId,
    };
  }

  Map<String, dynamic> _getNewData() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

    return {
      'visitingAddress': _visitAddressController.text,
      'purposeOfVisit': _purposeController.text,
      'priority': _selectedPriority,
      'availabilityStart': start.toIso8601String(),
      'availabilityEnd': end.toIso8601String(),
      'assignedFE': _selectedFeId,
      if (_coordinates != null) 'locationCoordinates': _coordinates,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.viewModel.updateTask(
      visitId: widget.visit.id,
      originalData: _getOriginalData(),
      newData: _getNewData(),
      onSuccess: () {
        SnackbarService.showSuccess('Task updated successfully');
        Navigator.pop(context);
      },
      onError: (msg) => SnackbarService.showError(msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
        ),
        child: Column(
          children: [
            _buildHandle(theme),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 12.sdp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Task', style: AppTextStyle.extraBold.custom(18.ssp, colorScheme.onSurface)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.x(), size: 20.sdp),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.sdp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Client Details', PhosphorIcons.userCircle()),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Client Name', widget.visit.client.name, PhosphorIcons.user()),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Mobile Number', widget.visit.client.contactNumber, PhosphorIcons.phone()),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Permanent Address', widget.visit.client.address, PhosphorIcons.house()),
                      SizedBox(height: 24.sdp),
                      _buildSectionHeader('Visit Information', PhosphorIcons.clipboardText()),
                      SizedBox(height: 12.sdp),
                      _buildAddressSearchField(theme),
                      if (widget.viewModel.addressSuggestions.isNotEmpty) _buildAddressSuggestions(theme),
                      SizedBox(height: 12.sdp),
                      _buildInputField(
                        controller: _purposeController,
                        label: 'Purpose of Visit',
                        icon: PhosphorIcons.notePencil(),
                      ),
                      SizedBox(height: 20.sdp),
                      _buildLabel('Priority', colorScheme),
                      _buildPriorityChips(colorScheme),
                      SizedBox(height: 24.sdp),
                      _buildSectionHeader('Timing & Assignment', PhosphorIcons.clock()),
                      SizedBox(height: 12.sdp),
                      _buildDatePicker(theme),
                      SizedBox(height: 12.sdp),
                      Row(
                        children: [
                          Expanded(child: _buildTimePicker(theme, isStart: true)),
                          SizedBox(width: 12.sdp),
                          Expanded(child: _buildTimePicker(theme, isStart: false)),
                        ],
                      ),
                      SizedBox(height: 20.sdp),
                      _buildFEDropdown(theme),
                      SizedBox(height: 32.sdp),
                      _buildSubmitButton(theme),
                      SizedBox(height: 24.sdp),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      width: 40.sdp,
      height: 4.sdp,
      margin: EdgeInsets.only(top: 12.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2.sdp),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18.sdp),
        SizedBox(width: 8.sdp),
        Text(title, style: AppTextStyle.bold.custom(14.ssp, theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.sdp),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sdp, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(width: 12.sdp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyle.normal.custom(10.ssp, theme.colorScheme.onSurface.withOpacity(0.5))),
              Text(value, style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon, Widget? suffixIcon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyle.normal.custom(13.ssp, colorScheme.onSurface.withOpacity(0.5)),
      prefixIcon: Icon(icon, size: 18.sdp, color: colorScheme.primary.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildAddressSearchField(ThemeData theme) {
    return TextFormField(
      controller: _visitAddressController,
      onChanged: (val) {
        widget.viewModel.onAddressSearchChanged(val);
        _fetchCoordinatesAndFEs();
      },
      maxLines: 2,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface),
      decoration: _inputDecoration(
        label: 'Visiting Address',
        icon: PhosphorIcons.mapPin(),
      ),
    );
  }

  Widget _buildAddressSuggestions(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(top: 4.sdp),
      constraints: BoxConstraints(maxHeight: 150.sdp),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.sdp),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.viewModel.addressSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = widget.viewModel.addressSuggestions[index];
          return ListTile(
            leading: Icon(PhosphorIcons.mapPin(), size: 18.sdp, color: theme.colorScheme.primary),
            title: Text(suggestion.address, style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface)),
            onTap: () {
              _visitAddressController.text = suggestion.address;
              _coordinates = suggestion.coordinates;
              widget.viewModel.addressSuggestions = [];
              _fetchCoordinatesAndFEs();
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildPriorityChips(ColorScheme colorScheme) {
    final priorities = {1: 'Highest', 2: 'High', 3: 'Medium', 4: 'Low', 5: 'Lowest'};
    return Wrap(
      spacing: 8.sdp,
      runSpacing: 10.sdp,
      children: priorities.entries.map((e) {
        final isSelected = _selectedPriority == e.key;
        final color = _getPriorityColor(e.key);
        return _buildChip(
          label: e.value,
          isSelected: isSelected,
          color: color,
          onTap: () => setState(() => _selectedPriority = e.key),
        );
      }).toList(),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required Color color, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.sdp),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 10.sdp),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyle.bold.custom(isSelected ? 12.ssp : 11.ssp, isSelected ? color : colorScheme.onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) => switch (priority) {
        1 => Colors.red,
        2 => Colors.orange,
        3 => Colors.green,
        4 => Colors.blue,
        _ => Colors.grey,
      };

  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sdp),
      child: Text(text, style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface)),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return _buildPickerContainer(
      icon: PhosphorIcons.calendar(),
      text: DateFormat('dd MMM, yyyy').format(_selectedDate),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          _fetchCoordinatesAndFEs();
        }
      },
    );
  }

  Widget _buildTimePicker(ThemeData theme, {required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isStart ? 'Slot Start' : 'Slot End', style: AppTextStyle.normal.custom(10.ssp, theme.colorScheme.onSurface.withOpacity(0.5))),
        SizedBox(height: 4.sdp),
        _buildPickerContainer(
          icon: PhosphorIcons.clock(),
          text: time.format(context),
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
            if (picked != null) {
              setState(() => isStart ? _startTime = picked : _endTime = picked);
              _fetchCoordinatesAndFEs();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPickerContainer({required IconData icon, required String text, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.sdp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          color: theme.cardColor,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sdp, color: theme.colorScheme.primary),
            SizedBox(width: 8.sdp),
            Text(text, style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildFEDropdown(ThemeData theme) {
    if (widget.viewModel.isLoadingFEs) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sdp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        color: theme.cardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedFeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Field Executive',
            labelStyle: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface.withOpacity(0.5)),
            border: InputBorder.none,
            icon: Icon(PhosphorIcons.userGear(), size: 18.sdp, color: theme.colorScheme.primary),
          ),
          items: widget.viewModel.availableFEs.map((fe) {
            final isNotAvailable = fe.isAvailable == false;
            return DropdownMenuItem(
              value: fe.id,
              enabled: !isNotAvailable,
              child: Row(
                children: [
                  Flexible(child: Text(fe.name, style: AppTextStyle.normal.custom(14.ssp, isNotAvailable ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
                  if (fe.isNearer == true) ...[
                    SizedBox(width: 4.sdp),
                    _buildTag('Suggested', Colors.blue, icon: PhosphorIcons.lightbulb(PhosphorIconsStyle.fill)),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedFeId = val),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, {PhosphorIconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 4.sdp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.sdp),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12.sdp, color: color), SizedBox(width: 4.sdp)],
          Text(text, style: TextStyle(color: color, fontSize: 8.ssp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 54.sdp,
      child: ElevatedButton(
        onPressed: widget.viewModel.isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.sdp)),
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        ),
        child: widget.viewModel.isSubmitting
            ? SizedBox(height: 20.sdp, width: 20.sdp, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
            : Text('Save Changes', style: AppTextStyle.bold.custom(16.ssp, theme.colorScheme.onPrimary)),
      ),
    );
  }
}
