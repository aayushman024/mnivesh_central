import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Models/route_optimization_models.dart';
import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';

class AddTaskScreen extends StatefulWidget {
  final List<double>? initialCoordinates;
  final String? initialAddress;
  final String? initialClientName;

  const AddTaskScreen({
    super.key,
    this.initialCoordinates,
    this.initialAddress,
    this.initialClientName,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RouteOptimizationViewModel _viewModel;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _visitAddressController = TextEditingController();
  final TextEditingController _additionalAddressController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String? _selectedFeId;

  bool get _hasExistingVisitLocation =>
      _visitAddressController.text.trim().isNotEmpty &&
      _viewModel.selectedCoordinates != null;

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
    _viewModel.resetAddTaskForm();

    if (widget.initialCoordinates != null) {
      _viewModel.selectedCoordinates = widget.initialCoordinates;
      _viewModel.fetchAvailableFEs();
    }
    if (widget.initialAddress != null) {
      _visitAddressController.text = widget.initialAddress!;
    }
    if (widget.initialClientName != null) {
      _nameController.text = widget.initialClientName!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.searchClientsImmediately(widget.initialClientName!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _visitAddressController.dispose();
    _additionalAddressController.dispose();
    _purposeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await _viewModel.submitTask(
      address: _visitAddressController.text,
      additionalAddressDetails: _additionalAddressController.text,
      mobile: _mobileController.text,
      purpose: _purposeController.text,
      selectedFeId: _selectedFeId,
      onSuccess: () {
        SnackbarService.showSuccess('Task created successfully');
        if (mounted) Navigator.pop(context);
      },
      onError: (msg) => SnackbarService.showError(msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const ModuleAppBar(title: 'Add New Visit', isBackIcon: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Client Information',
                  icon: PhosphorIcons.userCircle(),
                  children: [
                    _buildClientSearchField(theme),
                    if (_viewModel.clientSuggestions.isNotEmpty ||
                        _viewModel.temporaryClientName != null)
                      _buildClientSuggestions(theme),
                    SizedBox(height: 16.sdp),
                    _buildInputField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      icon: PhosphorIcons.phone(),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                SizedBox(height: 16.sdp),
                _buildSectionCard(
                  title: 'Visit Details',
                  icon: PhosphorIcons.clipboardText(),
                  children: [
                    _buildAddressSearchField(theme),
                    if (_viewModel.addressSuggestions.isNotEmpty)
                      _buildAddressSuggestions(theme),
                    if (_viewModel.selectedCoordinates != null) ...[
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
                              'map_${_viewModel.selectedCoordinates![0]}_${_viewModel.selectedCoordinates![1]}',
                            ),
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _viewModel.selectedCoordinates![1],
                                _viewModel.selectedCoordinates![0],
                              ),
                              zoom: 15.0,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('selected_location'),
                                position: LatLng(
                                  _viewModel.selectedCoordinates![1],
                                  _viewModel.selectedCoordinates![0],
                                ),
                              ),
                            },
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            trafficEnabled: false,
                            mapToolbarEnabled: false,
                            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16.sdp),
                    _buildInputField(
                      controller: _additionalAddressController,
                      label: 'Additional Address Details (Optional)',
                      icon: PhosphorIcons.mapTrifold(),
                    ),
                    SizedBox(height: 16.sdp),
                    _buildInputField(
                      controller: _purposeController,
                      label: 'Purpose of Visit',
                      icon: PhosphorIcons.notePencil(),
                    ),
                    SizedBox(height: 20.sdp),
                    _buildLabel('Visit Type', colorScheme),
                    _buildVisitTypeChips(colorScheme),
                    SizedBox(height: 20.sdp),
                    _buildLabel('Priority', colorScheme),
                    _buildPriorityChips(colorScheme),
                  ],
                ),
                SizedBox(height: 16.sdp),
                _buildSectionCard(
                  title: 'Timing & Assignment',
                  icon: PhosphorIcons.clock(),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.clockCounterClockwise(),
                              color: theme.colorScheme.primary.withOpacity(0.7),
                              size: 18.sdp,
                            ),
                            SizedBox(width: 8.sdp),
                            Text(
                              'Can Visit Anytime',
                              style: AppTextStyle.bold.custom(
                                13.ssp,
                                theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: _viewModel.canGoAnytime,
                            onChanged: (val) =>
                                _viewModel.updateCanGoAnytime(val),
                            activeColor: theme.colorScheme.primary,
                            activeTrackColor: theme.colorScheme.primary
                                .withOpacity(0.3),
                            inactiveThumbColor: theme.colorScheme.onSurface
                                .withOpacity(0.4),
                            inactiveTrackColor: theme.colorScheme.onSurface
                                .withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.sdp),
                    _buildDatePicker(theme),
                    SizedBox(height: 16.sdp),
                    Row(
                      children: [
                        Expanded(child: _buildTimePicker(theme, isStart: true)),
                        SizedBox(width: 12.sdp),
                        Expanded(
                          child: _buildTimePicker(theme, isStart: false),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.sdp),
                    _buildFEDropdown(theme),
                  ],
                ),
                SizedBox(height: 32.sdp),
                _buildSubmitButton(theme),
                SizedBox(height: 24.sdp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sdp),
      child: Text(
        text,
        style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20.sdp),
              SizedBox(width: 8.sdp),
              Text(
                title,
                style: AppTextStyle.extraBold.custom(
                  15.ssp,
                  theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Divider(
            height: 32.sdp,
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyle.normal.custom(
        14.ssp,
        Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyle.normal.custom(
        13.ssp,
        colorScheme.onSurface.withOpacity(0.5),
      ),
      prefixIcon: Icon(
        icon,
        size: 18.sdp,
        color: colorScheme.primary.withOpacity(0.7),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.sdp,
        vertical: 14.sdp,
      ),
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

  Widget _buildClientSearchField(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextFormField(
            controller: _nameController,
            onChanged: _viewModel.onClientSearchChanged,
            readOnly: _viewModel.isTemporaryClientMode,
            style: AppTextStyle.normal.custom(
              14.ssp,
              theme.colorScheme.onSurface.withOpacity(
                _viewModel.isTemporaryClientMode ? 0.6 : 1.0,
              ),
            ),
            decoration: _inputDecoration(
              label: _viewModel.isTemporaryClientMode
                  ? 'Temporary Client Name'
                  : 'Client Name / Search',
              icon: _viewModel.isTemporaryClientMode
                  ? PhosphorIcons.userCirclePlus()
                  : PhosphorIcons.user(),
              suffixIcon: _viewModel.isSearchingClients
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
                  : (_nameController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18.sdp),
                          onPressed: () {
                            _nameController.clear();
                            _viewModel.selectedClientId = null;
                            _viewModel.isTemporaryClientMode = false;
                            _viewModel.onClientSearchChanged('');
                          },
                        )
                      : null),
            ),
          ),
        ),
        SizedBox(width: 12.sdp),
        // Column(
        //   mainAxisSize: MainAxisSize.min,
        //   crossAxisAlignment: CrossAxisAlignment.center,
        //   children: [
        //     Text(
        //       'Search All',
        //       style: AppTextStyle.bold.custom(
        //         10.ssp,
        //         theme.colorScheme.onSurface.withOpacity(
        //           _viewModel.isTemporaryClientMode ? 0.3 : 0.6,
        //         ),
        //       ),
        //     ),
        //     SizedBox(height: 2.sdp),
        //     Transform.scale(
        //       scale: 0.8,
        //       child: Switch.adaptive(
        //         value: _viewModel.searchAllClients,
        //         onChanged: _viewModel.isTemporaryClientMode
        //             ? null
        //             : (val) =>
        //                   _viewModel.setSearchAll(val, _nameController.text),
        //         activeColor: theme.colorScheme.primary,
        //         activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
        //         inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(
        //           0.4,
        //         ),
        //         inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(
        //           0.1,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildAddressSearchField(ThemeData theme) {
    return TextFormField(
      controller: _visitAddressController,
      onChanged: _viewModel.onAddressSearchChanged,
      maxLines: 2,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Visiting Address is required';
        }
        if (_viewModel.selectedCoordinates == null) {
          return 'Please select a valid address from the map search suggestions';
        }
        return null;
      },
      decoration: _inputDecoration(
        label: 'Visiting Address / Map Search',
        icon: PhosphorIcons.mapPin(),
        suffixIcon: _viewModel.isSearchingAddresses
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
                      _viewModel.selectedCoordinates = null;
                      _viewModel.onAddressSearchChanged('');
                    },
                  )
                : null),
      ),
    );
  }

  Widget _buildClientSuggestions(ThemeData theme) {
    final hasSuggestions = _viewModel.clientSuggestions.isNotEmpty;
    final tempName = _viewModel.temporaryClientName;

    return _buildSuggestionList(
      itemCount: hasSuggestions
          ? _viewModel.clientSuggestions.length
          : (tempName != null ? 1 : 0),
      builder: (context, index) {
        if (!hasSuggestions && tempName != null) {
          return ListTile(
            leading: Icon(
              PhosphorIcons.userPlus(),
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Add as Temporary Client',
              style: AppTextStyle.bold.custom(
                13.ssp,
                theme.colorScheme.primary,
              ),
            ),
            subtitle: Text(
              '"$tempName"',
              style: AppTextStyle.normal.custom(
                11.ssp,
                theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            onTap: () => _viewModel.switchToTemporaryClientMode(
              tempName,
              _nameController,
            ),
          );
        }

        final client = _viewModel.clientSuggestions[index];
        return ListTile(
          title: Text(
            client.name,
            style: AppTextStyle.bold.custom(
              13.ssp,
              theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            client.address,
            style: AppTextStyle.normal.custom(
              11.ssp,
              theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
          ),
          onTap: () => _viewModel.selectClient(
            client,
            nameController: _nameController,
            mobileController: _mobileController,
            addressController: _visitAddressController,
            preserveExistingVisitLocation: _hasExistingVisitLocation,
          ),
        );
      },
    );
  }

  Widget _buildAddressSuggestions(ThemeData theme) {
    return _buildSuggestionList(
      itemCount: _viewModel.addressSuggestions.length,
      builder: (context, index) {
        final suggestion = _viewModel.addressSuggestions[index];
        return ListTile(
          leading: Icon(
            PhosphorIcons.mapPin(),
            size: 18.sdp,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            suggestion.address,
            style: AppTextStyle.normal.custom(
              12.ssp,
              theme.colorScheme.onSurface,
            ),
          ),
          onTap: () => _viewModel.selectAddress(
            suggestion,
            addressController: _visitAddressController,
          ),
        );
      },
    );
  }

  Widget _buildSuggestionList({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 4.sdp),
      constraints: BoxConstraints(maxHeight: 200.sdp),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.sdp),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: builder,
      ),
    );
  }

  Widget _buildVisitTypeChips(ColorScheme colorScheme) {
    const types = ['Collection', 'Handover', 'Exchange'];
    return Wrap(
      spacing: 10.sdp,
      runSpacing: 10.sdp,
      children: types.map((type) {
        final isSelected = _viewModel.selectedVisitType == type;
        return _buildChip(
          label: type,
          isSelected: isSelected,
          color: colorScheme.primary,
          onTap: () => _viewModel.updateVisitType(type),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityChips(ColorScheme colorScheme) {
    final priorities = {1: 'High', 2: 'Normal'};
    return Wrap(
      spacing: 8.sdp,
      runSpacing: 10.sdp,
      children: priorities.entries.map((e) {
        final isSelected = _viewModel.selectedPriority == e.key;
        final color = _getPriorityColor(e.key);
        return _buildChip(
          label: e.value,
          isSelected: isSelected,
          color: color,
          onTap: () => _viewModel.updatePriority(e.key),
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.sdp),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 10.sdp),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.sdp),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.bold.custom(
            isSelected ? 12.ssp : 11.ssp,
            isSelected ? color : colorScheme.onSurface.withOpacity(0.7),
          ),
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

  Widget _buildDatePicker(ThemeData theme) {
    return _buildPickerContainer(
      icon: PhosphorIcons.calendar(),
      text: DateFormat('dd MMM, yyyy').format(_viewModel.selectedDate),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _viewModel.selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) _viewModel.updateDate(date);
      },
    );
  }

  Widget _buildTimePicker(ThemeData theme, {required bool isStart}) {
    final time = isStart ? _viewModel.startTime : _viewModel.endTime;
    final isDisabled = _viewModel.canGoAnytime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStart ? 'Slot Start' : 'Slot End',
          style: AppTextStyle.normal.custom(
            10.ssp,
            theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.5),
          ),
        ),
        SizedBox(height: 4.sdp),
        _buildPickerContainer(
          icon: PhosphorIcons.clock(),
          text: isDisabled ? '--:--' : time.format(context),
          isDisabled: isDisabled,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null)
              isStart
                  ? _viewModel.updateStartTime(picked)
                  : _viewModel.updateEndTime(picked);
          },
        ),
      ],
    );
  }

  Widget _buildPickerContainer({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.all(12.sdp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.sdp),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            color: theme.cardColor,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18.sdp, color: theme.colorScheme.primary),
              SizedBox(width: 8.sdp),
              Text(
                text,
                style: AppTextStyle.bold.custom(
                  13.ssp,
                  theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFEDropdown(ThemeData theme) {
    if (_viewModel.isLoadingFEs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_viewModel.selectedCoordinates == null) {
      return Text(
        'Select location to see field executives',
        style: AppTextStyle.normal.custom(
          12.ssp,
          theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      );
    }

    final selectedFE = _viewModel.availableFEs.firstWhere(
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
              PhosphorIcons.userGear(),
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
              PhosphorIcons.caretDown(),
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
                          icon: Icon(PhosphorIcons.x(), size: 20.sdp),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _viewModel.availableFEs.isEmpty
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
                            itemCount: _viewModel.availableFEs.length,
                            separatorBuilder: (context, index) => SizedBox(height: 12.sdp),
                            itemBuilder: (context, index) {
                              final fe = _viewModel.availableFEs[index];
                              final isSelected = fe.id == _selectedFeId;
                              
                              final isNotAvailable = fe.isAvailable == false;
                              final isFeasible = fe.isFeasible;
                              final isSelectable = isFeasible && (!isNotAvailable || _viewModel.canGoAnytime);
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
                                                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
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
                                                icon: PhosphorIcons.mapPin(),
                                              ),
                                            if (fe.eta != null && fe.eta!.isNotEmpty)
                                              _buildTag(
                                                'ETA: ${fe.eta}',
                                                Colors.teal,
                                                icon: PhosphorIcons.navigationArrow(),
                                              ),
                                            if (fe.isNearer == true)
                                              _buildTag(
                                                'Suggested',
                                                Colors.blue,
                                                icon: PhosphorIcons.thumbsUp(PhosphorIconsStyle.fill),
                                              ),
                                            if (isNotAvailable && (fe.nextAvailableAt?.isNotEmpty ?? false))
                                              _buildTag(
                                                'Next: ${_formatNextAvailableAt(fe.nextAvailableAt!)}',
                                                Colors.orange,
                                                icon: PhosphorIcons.clockCounterClockwise(),
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
                                                  PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
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
                                        ] else if (isNotAvailable && !_viewModel.canGoAnytime) ...[
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
                                                  PhosphorIcons.clock(PhosphorIconsStyle.fill),
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
      padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 10.sdp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.sdp),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sdp, color: color),
            SizedBox(width: 4.sdp),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.ssp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNextAvailableAt(String rawValue) {
    final parsed = DateTime.tryParse(rawValue);
    if (parsed == null) return rawValue;
    final isOffsetAware = RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
    ).hasMatch(rawValue.trim());
    final istTime = isOffsetAware
        ? parsed.toUtc().add(const Duration(hours: 5, minutes: 30))
        : parsed;
    return DateFormat('dd MMM, hh:mm a').format(istTime);
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 54.sdp,
      child: ElevatedButton(
        onPressed: _viewModel.isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.sdp),
          ),
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        ),
        child: _viewModel.isSubmitting
            ? SizedBox(
                height: 20.sdp,
                width: 20.sdp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Text(
                'Create Visit Task',
                style: AppTextStyle.bold.custom(
                  16.ssp,
                  theme.colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }
}
