import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../Utils/DismissKeyboard.dart';
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
  late final TextEditingController _additionalAddressController;
  late final TextEditingController _purposeController;

  String? _selectedFeId;
  late int _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  List<double>? _coordinates;
  late bool _canGoAnytime;

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
    _additionalAddressController = TextEditingController(text: v.additionalAddressDetails);
    _purposeController = TextEditingController(text: v.purposeOfVisit);
    
    _selectedFeId = feId;
    _selectedPriority = priority;
    _canGoAnytime = v.canGoAnytime == true;

    final originalStart = start ?? DateTime.now();
    final isOnHold = v.status.toString().toLowerCase() == 'on-hold';

    // If on-hold and original time is in the past, default to "Now"
    if (isOnHold && originalStart.isBefore(DateTime.now())) {
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    } else {
      _selectedDate = originalStart;
      _startTime = TimeOfDay.fromDateTime(_selectedDate);
      _endTime = TimeOfDay.fromDateTime(end ?? _selectedDate.add(const Duration(hours: 1)));
    }
    
    // Trigger FE availability check once initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCoordinatesAndFEs();
    });
  }

  Future<void> _fetchCoordinatesAndFEs({bool forceCoordinates = false}) async {
    widget.viewModel.selectedDate = _selectedDate;
    widget.viewModel.startTime = _startTime;
    widget.viewModel.endTime = _endTime;
    widget.viewModel.canGoAnytime = _canGoAnytime;

    if (forceCoordinates || _coordinates == null) {
      if (_visitAddressController.text.isNotEmpty) {
        await widget.viewModel.fetchCoordinatesForAddress(_visitAddressController.text);
        // Synchronize internal state with viewmodel
        setState(() {
          _coordinates = widget.viewModel.selectedCoordinates;
        });
      }
    } else {
      widget.viewModel.selectedCoordinates = _coordinates;
      await widget.viewModel.fetchAvailableFEs();
    }
  }

  @override
  void dispose() {
    _visitAddressController.dispose();
    _additionalAddressController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String _formatNextAvailableAt(String rawValue) {
    final parsed = DateTime.tryParse(rawValue);
    if (parsed == null) return rawValue;
    final isOffsetAware = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawValue.trim());
    final istTime = isOffsetAware
        ? parsed.toUtc().add(const Duration(hours: 5, minutes: 30))
        : parsed;
    return DateFormat('dd MMM, hh:mm a').format(istTime);
  }

  Map<String, dynamic> _getOriginalData() {
    final v = widget.visit;
    final start = v is AssignedVisitDetails ? v.slotStart : (v as OnHoldVisitDetails).availabilityStart;
    final end = v is AssignedVisitDetails ? v.slotEnd : (v as OnHoldVisitDetails).availabilityEnd;
    final feId = v is AssignedVisitDetails ? v.feId : (v as OnHoldVisitDetails).assignedFeId;
    final originalDate = start ?? DateTime.now();

    return {
      'status': v.status,
      'visitingAddress': v.visitingAddress,
      'additionalAddressDetails': v.additionalAddressDetails,
      'purposeOfVisit': v.purposeOfVisit,
      'priority': int.tryParse(v.priority.toString()) ?? 3,
      'availabilityStart': start,
      'availabilityEnd': end,
      'slotStart': start,
      'slotEnd': end,
      'assignedFE': feId,
      'canGoAnytime': v.canGoAnytime == true,
      'date': originalDate,
    };
  }

  Map<String, dynamic> _getNewData() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

    return {
      'visitingAddress': _visitAddressController.text,
      'additionalAddressDetails': _additionalAddressController.text,
      'purposeOfVisit': _purposeController.text,
      'priority': _selectedPriority,
      'availabilityStart': _canGoAnytime ? null : start,
      'availabilityEnd': _canGoAnytime ? null : end,
      'slotStart': _canGoAnytime ? null : start,
      'slotEnd': _canGoAnytime ? null : end,
      'assignedFE': _selectedFeId,
      'locationCoordinates': _coordinates,
      'canGoAnytime': _canGoAnytime,
      'date': _selectedDate,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
    final isOnHold = widget.visit.status.toString().toLowerCase() == 'on-hold';

    if (!_canGoAnytime) {
      if (isOnHold && start.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        SnackbarService.showError('Re-assigned start time cannot be in the past');
        return;
      }

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        SnackbarService.showError('End time must be after start time');
        return;
      }
    }

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
      builder: (context, _) => DismissKeyboard(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
          ),
          child: SafeArea(
            top: false,
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
                    icon: Icon(PhosphorIconsRegular.x, size: 20.sdp),
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
                      _buildSectionHeader('Client Details', PhosphorIconsRegular.userCircle),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Client Name', widget.visit.client.name, PhosphorIconsRegular.user),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Mobile Number', widget.visit.client.contactNumber, PhosphorIconsRegular.phone),
                      SizedBox(height: 12.sdp),
                      _buildReadOnlyField('Permanent Address', widget.visit.client.address, PhosphorIconsRegular.house),
                      SizedBox(height: 24.sdp),
                      _buildSectionHeader('Visit Information', PhosphorIconsRegular.clipboardText),
                      SizedBox(height: 12.sdp),
                      _buildAddressSearchField(theme),
                      if (widget.viewModel.addressSuggestions.isNotEmpty) _buildAddressSuggestions(theme),
                      if (_coordinates != null) ...[
                        SizedBox(height: 12.sdp),
                        Container(
                          height: 180.sdp,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.sdp),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.15),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.sdp),
                            child: GoogleMap(
                              key: ValueKey(
                                'map_${_coordinates![0]}_${_coordinates![1]}',
                              ),
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _coordinates![1],
                                  _coordinates![0],
                                ),
                                zoom: 15.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: LatLng(
                                    _coordinates![1],
                                    _coordinates![0],
                                  ),
                                ),
                              },
                              zoomControlsEnabled: true,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                              trafficEnabled: false,
                              mapToolbarEnabled: false,
                              buildingsEnabled: false,
                              indoorViewEnabled: false,
                              tiltGesturesEnabled: false,
                              compassEnabled: false,
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 12.sdp),
                      _buildInputField(
                        controller: _additionalAddressController,
                        label: 'Additional Address Details (Optional)',
                        icon: PhosphorIconsRegular.mapTrifold,
                      ),
                      SizedBox(height: 12.sdp),
                      _buildInputField(
                        controller: _purposeController,
                        label: 'Purpose of Visit',
                        icon: PhosphorIconsRegular.notePencil,
                      ),
                      SizedBox(height: 20.sdp),
                      _buildLabel('Priority', colorScheme),
                      _buildPriorityChips(colorScheme),
                      SizedBox(height: 24.sdp),
                       _buildSectionHeader('Timing & Assignment', PhosphorIconsRegular.clock),
                      SizedBox(height: 12.sdp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIconsRegular.clockCounterClockwise, color: theme.colorScheme.primary.withOpacity(0.7), size: 18.sdp),
                              SizedBox(width: 8.sdp),
                              Text(
                                'Can Visit Anytime',
                                style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch.adaptive(
                              value: _canGoAnytime,
                              onChanged: (val) {
                                setState(() {
                                  _canGoAnytime = val;
                                });
                                _fetchCoordinatesAndFEs();
                              },
                              activeColor: theme.colorScheme.primary,
                              activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
                              inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.4),
                              inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sdp, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(width: 12.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyle.normal.custom(10.ssp, theme.colorScheme.onSurface.withOpacity(0.5))),
                Text(
                  value,
                  style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface.withOpacity(0.8)),
                  softWrap: true,
                ),
              ],
            ),
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
      textInputAction: TextInputAction.done,
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
        _coordinates = null;
        widget.viewModel.selectedCoordinates = null;
        widget.viewModel.onAddressSearchChanged(val);
        _fetchCoordinatesAndFEs(forceCoordinates: true);
      },
      maxLines: 2,
      textInputAction: TextInputAction.done,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Visiting Address is required';
        }
        if (_coordinates == null) {
          return 'Please select a valid address from the map search suggestions';
        }
        return null;
      },
      decoration: _inputDecoration(
        label: 'Visiting Address',
        icon: PhosphorIconsRegular.mapPin,
        suffixIcon: widget.viewModel.isSearchingAddresses
            ? Container(
                width: 20.sdp,
                height: 20.sdp,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 16.sdp,
                  height: 16.sdp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            : (_visitAddressController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18.sdp),
                    onPressed: () {
                      _visitAddressController.clear();
                      _coordinates = null;
                      widget.viewModel.selectedCoordinates = null;
                      widget.viewModel.onAddressSearchChanged('');
                      _fetchCoordinatesAndFEs(forceCoordinates: true);
                      setState(() {});
                    },
                  )
                : null),
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
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
            minVerticalPadding: 0,
            leading: Icon(PhosphorIconsRegular.mapPin, size: 18.sdp, color: theme.colorScheme.primary),
            title: Text(suggestion.address, style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface)),
            onTap: () {
              _visitAddressController.text = suggestion.address;
              _coordinates = suggestion.coordinates;
              widget.viewModel.addressSuggestions = [];
              _fetchCoordinatesAndFEs(forceCoordinates: true);
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildPriorityChips(ColorScheme colorScheme) {
    final priorities = {1: 'High', 2: 'Normal', 3: 'Low'};
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
      icon: PhosphorIconsRegular.calendar,
      text: DateFormat('dd MMM, yyyy').format(_selectedDate),
      onTap: () async {
        final isOnHold = widget.visit.status.toString().toLowerCase() == 'on-hold';
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate.isBefore(DateTime.now()) && isOnHold ? DateTime.now() : _selectedDate,
          firstDate: isOnHold ? DateTime.now() : DateTime(2020),
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
    final isDisabled = _canGoAnytime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isStart ? 'Slot Start' : 'Slot End', style: AppTextStyle.normal.custom(10.ssp, theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.5))),
        SizedBox(height: 4.sdp),
        _buildPickerContainer(
          icon: PhosphorIconsRegular.clock,
          text: isDisabled ? '--:--' : time.format(context),
          isDisabled: isDisabled,
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

  Widget _buildPickerContainer({required IconData icon, required String text, required VoidCallback onTap, bool isDisabled = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
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
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFEDropdown(ThemeData theme) {
    if (widget.viewModel.isLoadingFEs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_coordinates == null) {
      return Text(
        'Select location to see field executives',
        style: AppTextStyle.normal.custom(
          12.ssp,
          theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      );
    }

    final selectedFE = widget.viewModel.availableFEs.firstWhere(
      (fe) => fe.id == _selectedFeId,
      orElse: () => const FieldExecutiveSummary(id: '', name: '', employeeId: '', contactNumber: ''),
    );

    return InkWell(
      onTap: () => _showFeSelectorBottomSheet(theme),
      borderRadius: BorderRadius.circular(12.sdp),
      child: Container(
        padding: EdgeInsets.all(14.sdp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          color: theme.cardColor,
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.userGear,
              size: 20.sdp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 12.sdp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Executive',
                    style: AppTextStyle.normal.custom(
                      10.ssp,
                      theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 2.sdp),
                  Text(
                    selectedFE.id.isNotEmpty
                        ? '${selectedFE.name} (${selectedFE.employeeId})'
                        : 'Select Field Executive',
                    style: AppTextStyle.bold.custom(
                      14.ssp,
                      selectedFE.id.isNotEmpty
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretDown,
              size: 18.sdp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeSelectorBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.sdp)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.sdp,
                    height: 4.sdp,
                    margin: EdgeInsets.only(top: 12.sdp, bottom: 8.sdp),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2.sdp),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 12.sdp),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Field Executive',
                          style: AppTextStyle.extraBold.custom(
                            16.ssp,
                            theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(PhosphorIconsRegular.x, size: 20.sdp),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: widget.viewModel.availableFEs.isEmpty
                        ? Center(
                            child: Text(
                              'No Field Executives available',
                              style: AppTextStyle.normal.custom(
                                13.ssp,
                                theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(16.sdp),
                            itemCount: widget.viewModel.availableFEs.length,
                            separatorBuilder: (context, index) => SizedBox(height: 12.sdp),
                            itemBuilder: (context, index) {
                              final fe = widget.viewModel.availableFEs[index];
                              final isSelected = fe.id == _selectedFeId;
                              
                              final isNotAvailable = fe.isAvailable == false;
                              final isFeasible = fe.isFeasible;
                              final isSelectable = isFeasible && (!isNotAvailable || _canGoAnytime);
                              final isGrayedOut = !isSelectable;

                              return InkWell(
                                onTap: isSelectable
                                    ? () {
                                        setState(() {
                                          _selectedFeId = fe.id;
                                        });
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: Container(
                                  padding: EdgeInsets.all(12.sdp),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary.withOpacity(0.05)
                                        : (index % 2 == 0
                                            ? theme.cardColor
                                            : theme.colorScheme.surfaceVariant.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12.sdp),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline.withOpacity(0.1),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Opacity(
                                    opacity: isGrayedOut ? 0.55 : 1.0,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fe.name,
                                                style: AppTextStyle.bold.custom(
                                                  14.ssp,
                                                  theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                PhosphorIconsFill.checkCircle,
                                                color: theme.colorScheme.primary,
                                                size: 20.sdp,
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8.sdp),
                                        Wrap(
                                          spacing: 6.sdp,
                                          runSpacing: 6.sdp,
                                          children: [
                                            if (fe.distanceMeters != null)
                                              _buildTag(
                                                '${(fe.distanceMeters! / 1000).toStringAsFixed(1)} km',
                                                theme.colorScheme.primary,
                                                icon: PhosphorIconsRegular.mapPin,
                                              ),
                                            if (fe.eta != null && fe.eta!.isNotEmpty)
                                              _buildTag(
                                                'ETA: ${fe.eta}',
                                                Colors.teal,
                                                icon: PhosphorIconsRegular.navigationArrow,
                                              ),
                                            if (fe.isNearer == true)
                                              _buildTag(
                                                'Suggested',
                                                Colors.blue,
                                                icon: PhosphorIconsFill.thumbsUp,
                                              ),
                                            if (isNotAvailable && (fe.nextAvailableAt?.isNotEmpty ?? false))
                                              _buildTag(
                                                'Next: ${_formatNextAvailableAt(fe.nextAvailableAt!)}',
                                                Colors.orange,
                                                icon: PhosphorIconsRegular.clockCounterClockwise,
                                              ),
                                          ],
                                        ),
                                        if (!isFeasible) ...[
                                          SizedBox(height: 8.sdp),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8.sdp),
                                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  PhosphorIconsFill.warningCircle,
                                                  color: Colors.red,
                                                  size: 16.sdp,
                                                ),
                                                SizedBox(width: 6.sdp),
                                                Expanded(
                                                  child: Text(
                                                    'Not Feasible: ETA to location is ${fe.eta ?? "N/A"}, but slot ends before that.',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 10.ssp,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else if (isNotAvailable && !_canGoAnytime) ...[
                                          SizedBox(height: 8.sdp),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8.sdp),
                                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  PhosphorIconsFill.clock,
                                                  color: Colors.orange,
                                                  size: 16.sdp,
                                                ),
                                                SizedBox(width: 6.sdp),
                                                Expanded(
                                                  child: Text(
                                                    'Unavailable: Busy during this slot. Enable "Can Visit Anytime" to override.',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 10.ssp,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
