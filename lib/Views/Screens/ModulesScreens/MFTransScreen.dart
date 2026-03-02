import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../Models/mftrans_models.dart';
import '../../../ViewModels/mfTransaction_viewModel.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import 'MFTransFormScreen.dart';

// global provider for multi-step navigation
final mfTransStepProvider = StateProvider.autoDispose<int>((ref) => 1);

class MfTransactionScreen extends ConsumerStatefulWidget {
  const MfTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MfTransactionScreen> createState() => _MfTransactionScreenState();
}

class _MfTransactionScreenState extends ConsumerState<MfTransactionScreen> {
  TextEditingController? _invCtrl;
  TextEditingController? _panCtrl;
  TextEditingController? _headCtrl;

  final Map<String, GlobalKey> _cardKeys = {};

  Future<void> _pickDateTime(BuildContext context, WidgetRef ref) async {
    final state = ref.read(mfTransactionProvider);
    final now = DateTime.now();
    final defaultDateTime = state.selectedDate ?? DateTime(now.year, now.month, now.day, 10, 0);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: defaultDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(defaultDateTime),
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        ref.read(mfTransactionProvider.notifier).setDate(finalDateTime);
      }
    }
  }

  void _onUccSelected(String id) {
    ref.read(mfTransactionProvider.notifier).selectUcc(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _cardKeys[id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mfTransactionProvider);
    final viewModel = ref.read(mfTransactionProvider.notifier);
    final currentStep = ref.watch(mfTransStepProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(mfTransactionProvider, (previous, next) {
      if (previous?.selectedInvestor != next.selectedInvestor && next.selectedInvestor != null) {
        if (_invCtrl?.text != next.selectedInvestor!.name) _invCtrl?.text = next.selectedInvestor!.name;
        if (_panCtrl?.text != next.selectedInvestor!.pan) _panCtrl?.text = next.selectedInvestor!.pan;
        if (_headCtrl?.text != next.selectedInvestor!.familyHead) _headCtrl?.text = next.selectedInvestor!.familyHead;
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            icon: PhosphorIcon(PhosphorIcons.house(
              PhosphorIconsStyle.fill
            ))),
        title: Text(
            "MF Transaction",
            style: AppTextStyle.bold.large(colorScheme.onSurface).copyWith(fontSize: 18.ssp)
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(10.sdp),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              spacing: 8.sdp,
              children: [
                Expanded(child: Container(height: 4.sdp, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2.sdp)))),
                Expanded(child: Container(height: 4.sdp, decoration: BoxDecoration(color: currentStep >= 2 ? colorScheme.primary : colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(2.sdp)))),
                Expanded(child: Container(height: 4.sdp, decoration: BoxDecoration(color: currentStep >= 3 ? colorScheme.primary : colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(2.sdp)))),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(currentStep, state, viewModel),
            ),
          ),

          if (currentStep > 1 || state.selectedUccId != null)
            Positioned(
              bottom: 24.sdp,
              left: 24.sdp,
              right: 24.sdp,
              child: _buildPersistentBottomBar(currentStep, viewModel, colorScheme),
            )
        ],
      ),
    );
  }

  Widget _buildCurrentStep(int step, dynamic state, dynamic viewModel) {
    switch (step) {
      case 1: return _buildStep1(state, viewModel);
      case 2: return const MFTransFormStep2(key: ValueKey('step2'));
      case 3:
        return Container(
          key: const ValueKey('step3'),
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(10.sdp, 16.sdp, 10.sdp, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24.sdp), topRight: Radius.circular(24.sdp)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10.sdp, offset: Offset(0, -2.sdp))],
          ),
          child: Center(child: Text('Step 3: Verification & Submit', style: AppTextStyle.bold.normal(Theme.of(context).colorScheme.onSurface))),
        );
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPersistentBottomBar(int step, dynamic viewModel, ColorScheme colorScheme) {
    String leftText = "Previous";
    String rightText = "Proceed";
    VoidCallback onLeftTap;
    VoidCallback onRightTap;

    Color leftFgColor = colorScheme.onSurface;
    Color leftBgColor = colorScheme.surface;
    Color leftBorderColor = colorScheme.onSurface.withOpacity(0.2);
    Color rightBgColor = colorScheme.primary;

    if (step == 1) {
      leftText = "Deselect";
      leftFgColor = colorScheme.error;
      leftBgColor = colorScheme.error.withAlpha(15);
      leftBorderColor = Colors.red.shade200;
      onLeftTap = () => viewModel.deselectUcc();
      onRightTap = () => ref.read(mfTransStepProvider.notifier).state = 2;
    } else if (step == 2) {
      onLeftTap = () => ref.read(mfTransStepProvider.notifier).state = 1;
      onRightTap = () => ref.read(mfTransStepProvider.notifier).state = 3;
    } else {
      rightText = "Submit";
      rightBgColor = Colors.green;
      onLeftTap = () => ref.read(mfTransStepProvider.notifier).state = 2;
      onRightTap = () {
        // execute submit API
      };
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
      decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(32.sdp),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 10, blurRadius: 15.sdp, offset: Offset(0, 8.sdp))]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: TextButton(
              onPressed: onLeftTap,
              style: TextButton.styleFrom(
                  foregroundColor: leftFgColor,
                  backgroundColor: leftBgColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 15.sdp),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.sdp),
                      side: BorderSide(color: leftBorderColor, width: 0.5)
                  )
              ),
              child: Text(leftText, style: AppTextStyle.normal.normal(leftFgColor).copyWith(fontSize: 14.ssp)),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: ElevatedButton(
              onPressed: onRightTap,
              style: ElevatedButton.styleFrom(
                  backgroundColor: rightBgColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: EdgeInsets.symmetric(vertical: 15.sdp),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.sdp))
              ),
              child: Text(rightText, style: AppTextStyle.bold.normal(Colors.white).copyWith(fontSize: 15.ssp)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep1(dynamic state, dynamic viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = state.selectedDate != null
        ? DateFormat('dd-MM-yyyy  hh:mm a').format(state.selectedDate!)
        : "dd-mm-yyyy  --:--";

    return Column(
      key: const ValueKey('step1'),
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(10.sdp, 16.sdp, 10.sdp, 0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24.sdp), topRight: Radius.circular(24.sdp)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10.sdp, offset: Offset(0, -2.sdp))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18.sdp, 24.sdp, 18.sdp, 120.sdp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaction Preference", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 12.sdp),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPrefButton(title: "ASAP", isSelected: state.preference == TransPref.asap, onTap: () => viewModel.setPreference(TransPref.asap)),
                        SizedBox(width: 8.sdp),
                        _buildPrefButton(title: "Next Working Day", isSelected: state.preference == TransPref.nextWorkingDay, onTap: () => viewModel.setPreference(TransPref.nextWorkingDay)),
                        SizedBox(width: 8.sdp),
                        _buildPrefButton(title: "Select Date & Time", isSelected: state.preference == TransPref.custom, onTap: () => viewModel.setPreference(TransPref.custom)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.sdp),

                  if (state.preference != TransPref.asap && state.preference != TransPref.nextWorkingDay) ...[
                    Text("Date & Time", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8.sdp),
                    GestureDetector(
                      onTap: () => _pickDateTime(context, ref),
                      child: AbsorbPointer(
                        child: _buildInputField(hint: dateStr, suffixIcon: Icons.calendar_today_rounded, isBold: state.selectedDate != null),
                      ),
                    ),
                    SizedBox(height: 24.sdp),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Investor Name", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          SizedBox(
                            height: 24.sdp, width: 24.sdp,
                            child: Checkbox(value: true, onChanged: (v) {}, activeColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.sdp))),
                          ),
                          SizedBox(width: 8.sdp),
                          Text("Search All", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp)),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 8.sdp),
                  _buildSearchableDropdown(
                    viewModel: viewModel, hint: "Search by Name...", displayString: (option) => option.name,
                    onInitController: (ctrl) => _invCtrl = ctrl, searchFunction: viewModel.searchByName,
                  ),

                  SizedBox(height: 20.sdp),
                  Text("PAN Number", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.sdp),
                  _buildSearchableDropdown(
                    viewModel: viewModel, hint: "Search by PAN...", displayString: (option) => option.pan,
                    onInitController: (ctrl) => _panCtrl = ctrl, searchFunction: viewModel.searchByPan,
                  ),

                  SizedBox(height: 20.sdp),
                  Text("Family Head", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.sdp),
                  _buildSearchableDropdown(
                    viewModel: viewModel, hint: "Search by Family Head...", displayString: (option) => option.familyHead,
                    onInitController: (ctrl) => _headCtrl = ctrl, searchFunction: viewModel.searchByFamilyHead,
                  ),

                  SizedBox(height: 32.sdp),
                  SizedBox(
                    width: double.infinity,
                    height: 52.sdp,
                    child: ElevatedButton(
                      onPressed: state.isSearchingUcc ? null : viewModel.fetchUccData,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary.withAlpha(20),
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          side: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.sdp))
                      ),
                      child: state.isSearchingUcc
                          ? SizedBox(height: 20.sdp, width: 20.sdp, child: const CircularProgressIndicator.adaptive(strokeWidth: 2))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8.sdp,
                        children: [
                          PhosphorIcon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold), color: colorScheme.primary),
                          Text("Search UCC", style: AppTextStyle.bold.normal(colorScheme.primary).copyWith(fontSize: 16.ssp)),
                        ],
                      ),
                    ),
                  ),

                  if (state.showUcc) ...[
                    SizedBox(height: 32.sdp),
                    Text("Select UCC", style: AppTextStyle.bold.normal(colorScheme.onSurface).copyWith(fontSize: 16.ssp)),
                    SizedBox(height: 16.sdp),
                    ...state.uccData.map((data) => _buildUccCard(data, state.selectedUccId)).toList(),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // preserved private builders from your code
  Widget _buildSearchableDropdown({
    required MfTransactionViewModel viewModel,
    required String hint,
    required String Function(InvestorModel) displayString,
    required void Function(TextEditingController) onInitController,
    required Future<List<InvestorModel>> Function(String) searchFunction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Autocomplete<InvestorModel>(
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const Iterable<InvestorModel>.empty();
        return await searchFunction(textEditingValue.text);
      },
      displayStringForOption: displayString,
      onSelected: viewModel.selectInvestor,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        onInitController(controller);
        return TextFormField(
          controller: controller, focusNode: focusNode,
          style: AppTextStyle.normal.normal(colorScheme.onSurface).copyWith(fontSize: 14.ssp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle.normal.normal(colorScheme.onSurface.withOpacity(0.4)).copyWith(fontSize: 14.ssp),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.sdp), borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.sdp), borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.sdp), borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8, shadowColor: Colors.black12, borderRadius: BorderRadius.circular(16.sdp), color: theme.cardColor, clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250.sdp, maxWidth: MediaQuery.of(context).size.width - 48.sdp),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.sdp), shrinkWrap: true, itemCount: options.length,
                separatorBuilder: (_, _) => Divider(height: 1.sdp, color: colorScheme.onSurface.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.name, style: AppTextStyle.bold.small(colorScheme.onSurface).copyWith(fontSize: 14.ssp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.sdp),
                          Text("PAN: ${option.pan}  •  Head: ${option.familyHead}", style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 12.ssp)),
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

  Widget _buildInputField({required String hint, IconData? suffixIcon, bool isBold = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: AppTextStyle.normal.small(isBold ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 14.ssp, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
          if (suffixIcon != null) Icon(suffixIcon, color: colorScheme.primary, size: 20.sdp),
        ],
      ),
    );
  }

  Widget _buildPrefButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 10.sdp),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(24.sdp),
          border: Border.all(color: colorScheme.primary),
          boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 8.sdp, offset: Offset(0, 2.sdp))] : [],
        ),
        child: Text(
          title,
          style: AppTextStyle.normal.small(isSelected ? colorScheme.onPrimary : colorScheme.primary).copyWith(fontSize: 13.ssp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildUccCard(UccModel data, String? selectedUccId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    _cardKeys.putIfAbsent(data.id, () => GlobalKey());
    final isSelected = data.id == selectedUccId;

    return GestureDetector(
      onTap: () => _onUccSelected(data.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.sdp),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200), key: _cardKeys[data.id],
              decoration: BoxDecoration(
                  color: theme.cardColor, borderRadius: BorderRadius.circular(20.sdp),
                  border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1), width: isSelected ? 1.5.sdp : 1.sdp),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10.sdp, spreadRadius: 1.sdp)]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19.sdp),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200), padding: EdgeInsets.all(20.sdp),
                      decoration: BoxDecoration(color: isSelected ? colorScheme.primary.withOpacity(0.06) : Colors.transparent),
                      child: Row(
                        children: [
                          Container(padding: EdgeInsets.all(10.sdp), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.person_rounded, color: colorScheme.primary, size: 20.sdp)),
                          SizedBox(width: 16.sdp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.name, style: AppTextStyle.bold.normal(colorScheme.onSurface).copyWith(fontSize: 15.ssp)),
                                SizedBox(height: 2.sdp),
                                Text(data.id, style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 13.ssp)),
                              ],
                            ),
                          ),
                          if (data.isValidated)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 6.sdp),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20.sdp)),
                              child: Text("Validated", style: AppTextStyle.bold.small(Colors.green).copyWith(fontSize: 12.ssp)),
                            )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.sdp, 0, 20.sdp, 20.sdp),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final dashCount = (constraints.constrainWidth() / 8.sdp).floor();
                              return Flex(mainAxisAlignment: MainAxisAlignment.spaceBetween, direction: Axis.horizontal, children: List.generate(dashCount, (_) => SizedBox(width: 4.sdp, height: 1.sdp, child: ColoredBox(color: colorScheme.onSurface.withOpacity(0.2)))));
                            },
                          ),
                          SizedBox(height: 20.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoColumn("Joint 1", "--"), _buildInfoColumn("Joint 2", "--"), _buildInfoColumn("Tax Holding", "IND / SI"),
                            ],
                          ),
                          SizedBox(height: 16.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoColumn("BSE Status", data.bseStatus, valueColor: data.bseStatus == "Active" ? Colors.green : colorScheme.error),
                              _buildInfoColumn("Bank Detail", data.bank), _buildInfoColumn("Nominee", data.nominee),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -8.sdp, right: -8.sdp,
                child: Container(
                  padding: EdgeInsets.all(4.sdp),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(Icons.check_rounded, color: colorScheme.onPrimary, size: 16.sdp),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.normal.small(colorScheme.onSurface.withOpacity(0.6)).copyWith(fontSize: 12.ssp, fontWeight: FontWeight.w500)),
        SizedBox(height: 6.sdp),
        Text(value, style: AppTextStyle.normal.small(valueColor ?? colorScheme.onSurface).copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w600)),
      ],
    );
  }
}