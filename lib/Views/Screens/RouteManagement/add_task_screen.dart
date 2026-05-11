import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RouteOptimizationViewModel _viewModel;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _visitAddressController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String? _selectedFeId;

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
    _viewModel.resetAddTaskForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _visitAddressController.dispose();
    _purposeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    await _viewModel.submitTask(
      address: _visitAddressController.text,
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
                    if (_viewModel.clientSuggestions.isNotEmpty || _viewModel.temporaryClientName != null) _buildClientSuggestions(theme),
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
                    if (_viewModel.addressSuggestions.isNotEmpty) _buildAddressSuggestions(theme),
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
                    _buildDatePicker(theme),
                    SizedBox(height: 16.sdp),
                    Row(
                      children: [
                        Expanded(child: _buildTimePicker(theme, isStart: true)),
                        SizedBox(width: 12.sdp),
                        Expanded(child: _buildTimePicker(theme, isStart: false)),
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
      child: Text(text, style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface)),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.sdp),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
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
              Text(title, style: AppTextStyle.extraBold.custom(15.ssp, theme.colorScheme.onSurface)),
            ],
          ),
          Divider(height: 32.sdp, color: theme.colorScheme.outline.withOpacity(0.1)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyle.normal.custom(14.ssp, Theme.of(context).colorScheme.onSurface),
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

  Widget _buildClientSearchField(ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      onChanged: _viewModel.onClientSearchChanged,
      readOnly: _viewModel.isTemporaryClientMode,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface.withOpacity(_viewModel.isTemporaryClientMode ? 0.6 : 1.0)),
      decoration: _inputDecoration(
        label: _viewModel.isTemporaryClientMode ? 'Temporary Client Name' : 'Client Name / Search',
        icon: _viewModel.isTemporaryClientMode ? PhosphorIcons.userCirclePlus() : PhosphorIcons.user(),
        suffixIcon: _nameController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18.sdp),
                onPressed: () {
                  _nameController.clear();
                  _viewModel.selectedClientId = null;
                  _viewModel.isTemporaryClientMode = false;
                  _viewModel.onClientSearchChanged('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildAddressSearchField(ThemeData theme) {
    return TextFormField(
      controller: _visitAddressController,
      onChanged: _viewModel.onAddressSearchChanged,
      maxLines: 2,
      style: AppTextStyle.normal.custom(14.ssp, theme.colorScheme.onSurface),
      decoration: _inputDecoration(
        label: 'Visiting Address / Map Search',
        icon: PhosphorIcons.mapPin(),
        suffixIcon: _visitAddressController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18.sdp),
                onPressed: () {
                  _visitAddressController.clear();
                  _viewModel.selectedCoordinates = null;
                  _viewModel.onAddressSearchChanged('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildClientSuggestions(ThemeData theme) {
    final hasSuggestions = _viewModel.clientSuggestions.isNotEmpty;
    final tempName = _viewModel.temporaryClientName;

    return _buildSuggestionList(
      itemCount: hasSuggestions ? _viewModel.clientSuggestions.length : (tempName != null ? 1 : 0),
      builder: (context, index) {
        if (!hasSuggestions && tempName != null) {
          return ListTile(
            leading: Icon(PhosphorIcons.userPlus(), color: theme.colorScheme.primary),
            title: Text('Add as Temporary Client', style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.primary)),
            subtitle: Text('"$tempName"', style: AppTextStyle.normal.custom(11.ssp, theme.colorScheme.onSurface.withOpacity(0.6))),
            onTap: () => _viewModel.switchToTemporaryClientMode(tempName, _nameController),
          );
        }
        
        final client = _viewModel.clientSuggestions[index];
        return ListTile(
          title: Text(client.name, style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.onSurface)),
          subtitle: Text(client.address, style: AppTextStyle.normal.custom(11.ssp, theme.colorScheme.onSurface.withOpacity(0.6)), maxLines: 1),
          onTap: () => _viewModel.selectClient(client, nameController: _nameController, mobileController: _mobileController, addressController: _visitAddressController),
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
          leading: Icon(PhosphorIcons.mapPin(), size: 18.sdp, color: theme.colorScheme.primary),
          title: Text(suggestion.address, style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface)),
          onTap: () => _viewModel.selectAddress(suggestion, addressController: _visitAddressController),
        );
      },
    );
  }

  Widget _buildSuggestionList({required int itemCount, required Widget Function(BuildContext, int) builder}) {
    return Container(
      margin: EdgeInsets.only(top: 4.sdp),
      constraints: BoxConstraints(maxHeight: 200.sdp),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.sdp),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListView.builder(shrinkWrap: true, itemCount: itemCount, itemBuilder: builder),
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
    final priorities = {1: 'Highest', 2: 'High', 3: 'Medium', 4: 'Low', 5: 'Lowest'};
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
            if (picked != null) isStart ? _viewModel.updateStartTime(picked) : _viewModel.updateEndTime(picked);
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
    if (_viewModel.isLoadingFEs) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    if (_viewModel.selectedCoordinates == null) return Text('Select location to see field executives', style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface.withOpacity(0.5)));

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
          decoration: InputDecoration(
            labelText: 'Field Executive',
            labelStyle: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface.withOpacity(0.5)),
            border: InputBorder.none,
            icon: Icon(PhosphorIcons.userGear(), size: 18.sdp, color: theme.colorScheme.primary),
          ),
          items: _viewModel.availableFEs.map((fe) {
            final isNotAvailable = fe.isAvailable == false;
            return DropdownMenuItem(
              value: fe.id,
              enabled: !isNotAvailable,
              child: Row(
                children: [
                  Text(fe.name, style: AppTextStyle.normal.custom(14.ssp, isNotAvailable ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis,),
                  if (fe.isNearer == true) ...[
                    SizedBox(width: 8.sdp),
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
          Text(text, style: TextStyle(color: color, fontSize: 10.ssp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.sdp)),
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        ),
        child: _viewModel.isSubmitting
            ? SizedBox(height: 20.sdp, width: 20.sdp, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
            : Text('Create Visit Task', style: AppTextStyle.bold.custom(16.ssp, theme.colorScheme.onPrimary)),
      ),
    );
  }
}
