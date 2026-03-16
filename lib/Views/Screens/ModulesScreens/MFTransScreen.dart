// lib/Views/MFTransaction/mf_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:mnivesh_central/Utils/DismissKeyboard.dart';
import 'package:mnivesh_central/Views/Screens/ModulesScreens/MFTransCompletedScreen.dart';
import 'package:mnivesh_central/Views/Screens/ModulesScreens/MFTransReviewScreen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/mftrans_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/mfTransForm_viewModel.dart';
import '../../../ViewModels/mfTransaction_viewModel.dart';
import '../../Widgets/MFTrans/formComponents.dart';
import 'MFTransFormScreen.dart';

// ─────────────────────────────────────────────
// Step Provider
// ─────────────────────────────────────────────

final mfTransStepProvider = StateProvider<int>((ref) => 1);

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class MfTransactionScreen extends ConsumerStatefulWidget {
  const MfTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MfTransactionScreen> createState() =>
      _MfTransactionScreenState();
}

class _MfTransactionScreenState extends ConsumerState<MfTransactionScreen> {
  // Controllers for the three autocomplete fields
  TextEditingController? _invCtrl;
  TextEditingController? _panCtrl;
  TextEditingController? _headCtrl;

  final Map<String, GlobalKey> _cardKeys = {};

  // ── DateTime Picker ────────────────────────────────────────────────────────

  Future<void> _pickDateTime() async {
    final state = ref.read(mfTransactionProvider);
    final pref = state.preference;

    final now = DateTime.now();
    final defaultDT =
        state.selectedDate ?? DateTime(now.year, now.month, now.day, 10, 0);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: defaultDT,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    // ── DATE ONLY ──
    if (pref == TransPref.customDate) {
      ref
          .read(mfTransactionProvider.notifier)
          .setDate(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
      return;
    }

    // ── DATE + TIME ──
    if (pref == TransPref.customeDateTime) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(defaultDT),
      );

      if (pickedTime != null) {
        ref
            .read(mfTransactionProvider.notifier)
            .setDate(
              DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              ),
            );
      }
    }
  }

  // ── UCC scroll-to-selected ────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mfTransactionProvider);
    final viewModel = ref.read(mfTransactionProvider.notifier);
    final currentStep = ref.watch(mfTransStepProvider);
    final formState = ref.watch(mfTransFormProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sync autocomplete controllers when investor is auto-selected
    ref.listen(mfTransactionProvider, (prev, next) {
      if (prev?.selectedInvestor != next.selectedInvestor &&
          next.selectedInvestor != null) {
        final inv = next.selectedInvestor!;
        if (_invCtrl?.text != inv.name) _invCtrl?.text = inv.name;
        if (_panCtrl?.text != inv.pan) _panCtrl?.text = inv.pan;
        if (_headCtrl?.text != inv.familyHead) _headCtrl?.text = inv.familyHead;
      }
    });

    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          systemOverlayStyle: theme.brightness == Brightness.light
              ? SystemUiOverlayStyle
                    .dark // Dark icons for Light Mode
              : SystemUiOverlayStyle.light,
          // Light icons for Dark Mode
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: PhosphorIcon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
          ),
          title: Text(
            'MF Transaction Form',
            style: AppTextStyle.bold
                .large(colorScheme.onSurface)
                .copyWith(fontSize: 18.ssp),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(10.sdp),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                spacing: 10.sdp,
                children: [
                  Expanded(child: _StepBar(filled: true)),
                  Expanded(child: _StepBar(filled: currentStep >= 2)),
                  Expanded(child: _StepBar(filled: currentStep >= 3)),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (currentStep == 2 &&
                      formState.savedTransactions.isNotEmpty)
                    _SavedTransactionsAccordion(
                      transactions: formState.savedTransactions,
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStep(currentStep, state, viewModel),
                    ),
                  ),
                ],
              ),
            ),
            if (currentStep > 1 || state.selectedUccId != null)
              Positioned(
                bottom: 24.sdp,
                left: 24.sdp,
                right: 24.sdp,
                child: _BottomBar(
                  currentStep: currentStep,
                  viewModel: viewModel,
                  onValidateStep1: () => viewModel.validateStep1(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Step Router ────────────────────────────────────────────────────────────

  Widget _buildStep(
    int step,
    MfTransactionState state,
    MfTransactionViewModel viewModel,
  ) {
    switch (step) {
      case 1:
        return _Step1(
          key: const ValueKey('step1'),
          state: state,
          viewModel: viewModel,
          onInvCtrl: (c) => _invCtrl = c,
          onPanCtrl: (c) => _panCtrl = c,
          onHeadCtrl: (c) => _headCtrl = c,
          onUccSelected: _onUccSelected,
          cardKeys: _cardKeys,
          onPickDateTime: _pickDateTime,
        );
      case 2:
        return const MFTransFormStep2();
      case 3:
        return MFTransFormStep3();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────
// Step 3 Placeholder
// ─────────────────────────────────────────────

// class _Step3Placeholder extends StatelessWidget {
//   const _Step3Placeholder({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       key: const ValueKey('step3'),
//       width: double.infinity,
//       margin: EdgeInsets.fromLTRB(10.sdp, 16.sdp, 10.sdp, 0),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24.sdp),
//           topRight: Radius.circular(24.sdp),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10.sdp,
//             offset: Offset(0, -2.sdp),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           'Step 3: Verification & Submit',
//           style: AppTextStyle.bold.normal(theme.colorScheme.onSurface),
//         ),
//       ),
//     );
//   }
// }=

// ─────────────────────────────────────────────
// AppBar Step Indicator
// ─────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final bool filled;

  const _StepBar({required this.filled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 4.sdp,
      decoration: BoxDecoration(
        color: filled
            ? colorScheme.primary
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.sdp),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Persistent Bottom Bar
// ─────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final int currentStep;
  final MfTransactionViewModel viewModel;
  final bool Function() onValidateStep1;

  const _BottomBar({
    required this.currentStep,
    required this.viewModel,
    required this.onValidateStep1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    String leftText = 'Previous';
    String rightText = 'Proceed';
    Color leftFg = colorScheme.onSurface;
    Color leftBg = colorScheme.surface;
    Color leftBorder = colorScheme.onSurface.withOpacity(0.2);
    Color rightBg = colorScheme.primary;
    VoidCallback onLeft;
    VoidCallback onRight;
    bool isLoading = false;

    if (currentStep == 1) {
      leftText = 'Deselect';
      leftFg = colorScheme.error;
      leftBg = colorScheme.error.withAlpha(15);
      leftBorder = Colors.red.shade200;
      onLeft = () => viewModel.deselectUcc();
      onRight = () {
        if (onValidateStep1()) {
          ref.read(mfTransStepProvider.notifier).state = 2;
        }
      };
    } else if (currentStep == 2) {
      onLeft = () => ref.read(mfTransStepProvider.notifier).state = 1;
      onRight = () => ref.read(mfTransStepProvider.notifier).state = 3;
    } else {
      rightText = 'Submit';
      rightBg = Colors.green;
      onLeft = () => ref.read(mfTransStepProvider.notifier).state = 2;
      onRight = () async {
        // show loading popup
        showDialog(
          context: context,

          barrierDismissible: false, // prevent user from tapping out
          builder: (ctx) => Center(
            child: Container(
              padding: EdgeInsets.all(20.sdp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator.adaptive(),
            ),
          ),
        );

        // fake api processing delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          Navigator.of(context).pop(); // dismiss loading dialog
          // ── CLEAR ALL DATA FROM MEMORY ──
          ref.read(mfTransFormProvider.notifier).clearForm();
          ref.invalidate(mfTransactionProvider); // Clears Step 1 (Investor/UCC)
          ref.invalidate(mfTransStepProvider); // Resets back to Step 1

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MFTransCompletedScreen(),
            ),
          );
        }
      };
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32.sdp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 10,
            blurRadius: 15.sdp,
            offset: Offset(0, 8.sdp),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onLeft,
              style: TextButton.styleFrom(
                foregroundColor: leftFg,
                backgroundColor: leftBg,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 15.sdp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.sdp),
                  side: BorderSide(color: leftBorder, width: 0.5),
                ),
              ),
              child: Text(
                leftText,
                style: AppTextStyle.normal
                    .normal(leftFg)
                    .copyWith(fontSize: 14.ssp),
              ),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: ElevatedButton(
              onPressed: onRight,
              style: ElevatedButton.styleFrom(
                backgroundColor: rightBg,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: EdgeInsets.symmetric(vertical: 15.sdp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.sdp),
                ),
              ),
              child: Text(
                rightText,
                style: AppTextStyle.bold
                    .normal(Colors.white)
                    .copyWith(fontSize: 15.ssp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 1 Widget
// ─────────────────────────────────────────────

class _Step1 extends ConsumerWidget {
  final MfTransactionState state;
  final MfTransactionViewModel viewModel;
  final void Function(TextEditingController) onInvCtrl;
  final void Function(TextEditingController) onPanCtrl;
  final void Function(TextEditingController) onHeadCtrl;
  final void Function(String) onUccSelected;
  final Map<String, GlobalKey> cardKeys;
  final VoidCallback onPickDateTime;

  const _Step1({
    Key? key,
    required this.state,
    required this.viewModel,
    required this.onInvCtrl,
    required this.onPanCtrl,
    required this.onHeadCtrl,
    required this.onUccSelected,
    required this.cardKeys,
    required this.onPickDateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = state.selectedDate != null
        ? (state.preference == TransPref.customDate
              ? DateFormat('dd/MM/yyyy').format(state.selectedDate!)
              : DateFormat('dd/MM/yyyy,  hh:mm a').format(state.selectedDate!))
        : 'dd/mm/yyyy';

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(10.sdp, 16.sdp, 10.sdp, 0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.sdp),
                topRight: Radius.circular(24.sdp),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10.sdp,
                  offset: Offset(0, -2.sdp),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18.sdp, 24.sdp, 18.sdp, 120.sdp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Transaction Preference ───────────────────────────────
                  Text(
                    'Transaction Preference',
                    style: AppTextStyle.normal
                        .small(colorScheme.onSurface.withOpacity(0.6))
                        .copyWith(
                          fontSize: 13.ssp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  SizedBox(height: 12.sdp),
                  _PreferenceSelector(
                    selectedPref: state.preference,
                    onPrefSelected: viewModel.setPreference,
                  ),
                  SizedBox(height: 24.sdp),

                  // ── Custom Date Picker ───────────────────────────────────
                  if (state.preference != TransPref.asap &&
                      state.preference != TransPref.nextWorkingDay) ...[
                    Text(
                      state.preference == TransPref.customDate
                          ? 'Date'
                          : 'Date & Time',
                      style: AppTextStyle.normal
                          .small(colorScheme.onSurface.withOpacity(0.6))
                          .copyWith(
                            fontSize: 13.ssp,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.sdp),
                    GestureDetector(
                      onTap: onPickDateTime,
                      child: AbsorbPointer(
                        child: _InputField(
                          hint: dateStr,
                          suffixIcon: Icons.calendar_today_rounded,
                          isBold: state.selectedDate != null,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.sdp),
                  ],

                  // ── Investor Name ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Investor Name',
                        style: AppTextStyle.normal
                            .small(colorScheme.onSurface.withOpacity(0.6))
                            .copyWith(
                              fontSize: 13.ssp,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 24.sdp,
                            width: 24.sdp,
                            child: Checkbox(
                              value: true,
                              onChanged: (_) {},
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.sdp),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.sdp),
                          Text(
                            'Search All',
                            style: AppTextStyle.normal
                                .small(colorScheme.onSurface.withOpacity(0.6))
                                .copyWith(fontSize: 13.ssp),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sdp),
                  _InvestorAutocomplete(
                    hint: 'Search by Name...',
                    displayString: (o) => o.name,
                    onInitController: onInvCtrl,
                    searchFunction: viewModel.searchByName,
                    onSelected: viewModel.selectInvestor,
                  ),

                  SizedBox(height: 20.sdp),
                  Text(
                    'PAN Number',
                    style: AppTextStyle.normal
                        .small(colorScheme.onSurface.withOpacity(0.6))
                        .copyWith(
                          fontSize: 13.ssp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  SizedBox(height: 8.sdp),
                  _InvestorAutocomplete(
                    hint: 'Search by PAN...',
                    displayString: (o) => o.pan,
                    onInitController: onPanCtrl,
                    searchFunction: viewModel.searchByPan,
                    onSelected: viewModel.selectInvestor,
                  ),

                  SizedBox(height: 20.sdp),
                  Text(
                    'Family Head',
                    style: AppTextStyle.normal
                        .small(colorScheme.onSurface.withOpacity(0.6))
                        .copyWith(
                          fontSize: 13.ssp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  SizedBox(height: 8.sdp),
                  _InvestorAutocomplete(
                    hint: 'Search by Family Head...',
                    displayString: (o) => o.familyHead,
                    onInitController: onHeadCtrl,
                    searchFunction: viewModel.searchByFamilyHead,
                    onSelected: viewModel.selectInvestor,
                  ),

                  SizedBox(height: 32.sdp),

                  // ── Search UCC Button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52.sdp,
                    child: ElevatedButton(
                      onPressed: state.isSearchingUcc
                          ? null
                          : viewModel.fetchUccData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withAlpha(20),
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5.sdp,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.sdp),
                        ),
                      ),
                      child: state.isSearchingUcc
                          ? SizedBox(
                              height: 20.sdp,
                              width: 20.sdp,
                              child: const CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.magnifyingGlass(
                                    PhosphorIconsStyle.bold,
                                  ),
                                  color: colorScheme.primary,
                                ),
                                SizedBox(width: 8.sdp),
                                Text(
                                  'Search UCC',
                                  style: AppTextStyle.bold
                                      .normal(colorScheme.primary)
                                      .copyWith(fontSize: 16.ssp),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── UCC List ─────────────────────────────────────────────
                  if (state.showUcc) ...[
                    SizedBox(height: 32.sdp),
                    Text(
                      'Select UCC',
                      style: AppTextStyle.bold
                          .normal(colorScheme.onSurface)
                          .copyWith(fontSize: 16.ssp),
                    ),
                    SizedBox(height: 16.sdp),
                    ...state.uccData
                        .map(
                          (data) => _UccCard(
                            data: data,
                            selectedUccId: state.selectedUccId,
                            cardKeys: cardKeys,
                            onTap: onUccSelected,
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Transaction Preference Auto-Scrolling Selector
// ─────────────────────────────────────────────

class _PreferenceSelector extends StatefulWidget {
  final TransPref selectedPref;
  final ValueChanged<TransPref> onPrefSelected;

  const _PreferenceSelector({
    super.key,
    required this.selectedPref,
    required this.onPrefSelected,
  });

  @override
  State<_PreferenceSelector> createState() => _PreferenceSelectorState();
}

class _PreferenceSelectorState extends State<_PreferenceSelector> {
  // GlobalKeys track the position of each button
  final List<GlobalKey> _keys = List.generate(4, (_) => GlobalKey());

  final List<Map<String, dynamic>> _prefs = [
    {'title': 'ASAP', 'value': TransPref.asap},
    {'title': 'Next Working Day', 'value': TransPref.nextWorkingDay},
    {'title': 'Select Date', 'value': TransPref.customDate},
    {'title': 'Select Date & Time', 'value': TransPref.customeDateTime},
  ];

  void _scrollToCenter(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _keys[index];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.5, // 0.5 perfectly aligns the item to the center
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 8.sdp,
        children: List.generate(_prefs.length, (index) {
          final pref = _prefs[index];
          final isSelected = widget.selectedPref == pref['value'];

          return _PrefButton(
            key: _keys[index], // Pass the key for position tracking
            title: pref['title'] as String,
            isSelected: isSelected,
            onTap: () {
              widget.onPrefSelected(pref['value'] as TransPref);
              _scrollToCenter(index); // Trigger auto-scroll on tap
            },
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Preference Button
// ─────────────────────────────────────────────

class _PrefButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrefButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8.sdp,
                    offset: Offset(0, 2.sdp),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: AppTextStyle.normal
              .small(isSelected ? colorScheme.onPrimary : colorScheme.primary)
              .copyWith(
                fontSize: 13.ssp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Date / generic Input Display Field
// ─────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String hint;
  final IconData? suffixIcon;
  final bool isBold;

  const _InputField({required this.hint, this.suffixIcon, this.isBold = false});

  @override
  Widget build(BuildContext context) {
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
          Text(
            hint,
            style: AppTextStyle.normal
                .small(
                  isBold
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.6),
                )
                .copyWith(
                  fontSize: 14.ssp,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon, color: colorScheme.primary, size: 20.sdp),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Investor Autocomplete
// ─────────────────────────────────────────────

class _InvestorAutocomplete extends StatelessWidget {
  final String hint;
  final String Function(InvestorModel) displayString;
  final void Function(TextEditingController) onInitController;
  final Future<List<InvestorModel>> Function(String) searchFunction;
  final void Function(InvestorModel) onSelected;

  const _InvestorAutocomplete({
    required this.hint,
    required this.displayString,
    required this.onInitController,
    required this.searchFunction,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Autocomplete<InvestorModel>(
      optionsBuilder: (tev) async {
        if (tev.text.isEmpty) return const [];
        return searchFunction(tev.text);
      },
      displayStringForOption: displayString,
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
        onInitController(ctrl);
        return TextFormField(
          controller: ctrl,
          focusNode: focus,
          style: AppTextStyle.normal
              .normal(colorScheme.onSurface)
              .copyWith(fontSize: 14.ssp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle.normal
                .normal(colorScheme.onSurface.withOpacity(0.4))
                .copyWith(fontSize: 14.ssp),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.sdp,
              vertical: 16.sdp,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.sdp),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5.sdp,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSel, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(16.sdp),
            color: theme.cardColor,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250.sdp,
                maxWidth: MediaQuery.of(ctx).size.width - 48.sdp,
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.sdp),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1.sdp,
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
                itemBuilder: (ctx, i) {
                  final option = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSel(option),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.sdp,
                        vertical: 14.sdp,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.name,
                            style: AppTextStyle.bold
                                .small(colorScheme.onSurface)
                                .copyWith(
                                  fontSize: 14.ssp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 4.sdp),
                          Text(
                            'PAN: ${option.pan}  •  Head: ${option.familyHead}',
                            style: AppTextStyle.normal
                                .small(colorScheme.onSurface.withOpacity(0.6))
                                .copyWith(fontSize: 12.ssp),
                          ),
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
}

// ─────────────────────────────────────────────
// UCC Card
// ─────────────────────────────────────────────

class _UccCard extends StatelessWidget {
  final UccModel data;
  final String? selectedUccId;
  final Map<String, GlobalKey> cardKeys;
  final void Function(String) onTap;

  const _UccCard({
    required this.data,
    required this.selectedUccId,
    required this.cardKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    cardKeys.putIfAbsent(data.id, () => GlobalKey());
    final isSelected = data.id == selectedUccId;

    return GestureDetector(
      onTap: () => onTap(data.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.sdp),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              key: cardKeys[data.id],
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20.sdp),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.1),
                  width: isSelected ? 1.5.sdp : 1.sdp,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10.sdp,
                    spreadRadius: 1.sdp,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19.sdp),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(20.sdp),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.06)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.sdp),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: colorScheme.primary,
                              size: 20.sdp,
                            ),
                          ),
                          SizedBox(width: 16.sdp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.name,
                                  style: AppTextStyle.bold
                                      .normal(colorScheme.onSurface)
                                      .copyWith(fontSize: 15.ssp),
                                ),
                                SizedBox(height: 2.sdp),
                                Text(
                                  data.id,
                                  style: AppTextStyle.normal
                                      .small(
                                        colorScheme.onSurface.withOpacity(0.6),
                                      )
                                      .copyWith(fontSize: 13.ssp),
                                ),
                              ],
                            ),
                          ),
                          if (data.isValidated)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.sdp,
                                vertical: 6.sdp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.sdp),
                              ),
                              child: Text(
                                'Validated',
                                style: AppTextStyle.bold
                                    .small(Colors.green)
                                    .copyWith(fontSize: 12.ssp),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.sdp, 0, 20.sdp, 20.sdp),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final count =
                                  (constraints.constrainWidth() / 8.sdp)
                                      .floor();
                              return Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  count,
                                  (_) => SizedBox(
                                    width: 4.sdp,
                                    height: 1.sdp,
                                    child: ColoredBox(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol('Joint 1', '--'),
                              _InfoCol('Joint 2', '--'),
                              _InfoCol('Tax Holding', 'IND / SI'),
                            ],
                          ),
                          SizedBox(height: 16.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol(
                                'BSE Status',
                                data.bseStatus,
                                valueColor: data.bseStatus == 'Active'
                                    ? Colors.green
                                    : colorScheme.error,
                              ),
                              _InfoCol('Bank Detail', data.bank),
                              _InfoCol('Nominee', data.nominee),
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
                top: -8.sdp,
                right: -8.sdp,
                child: Container(
                  padding: EdgeInsets.all(4.sdp),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimary,
                    size: 16.sdp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCol(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.normal
              .small(colorScheme.onSurface.withOpacity(0.6))
              .copyWith(fontSize: 12.ssp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 6.sdp),
        Text(
          value,
          style: AppTextStyle.normal
              .small(valueColor ?? colorScheme.onSurface)
              .copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

//saved trax
// ─────────────────────────────────────────────
// Expandable Cart / Saved Transactions Widget
// ─────────────────────────────────────────────

class _SavedTransactionsAccordion extends ConsumerWidget {
  final List<Map<String, dynamic>> transactions;

  const _SavedTransactionsAccordion({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(10.sdp, 10.sdp, 10.sdp, 0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.sdp),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Theme(
          // hide expansion tile borders
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content tightly
              children: transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final tx = entry.value;
                final isLast = index == transactions.length - 1;

                return Column(
                  children: [
                    ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 16.sdp),
                      childrenPadding: EdgeInsets.fromLTRB(
                        16.sdp,
                        0,
                        16.sdp,
                        16.sdp,
                      ),
                      title: Row(
                        spacing: 8.sdp,
                        children: [
                          Text(
                            'Transaction ${index + 1}',
                            style: AppTextStyle.bold
                                .small(colorScheme.onSurface)
                                .copyWith(fontSize: 14.ssp),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.sdp,
                              vertical: 4.sdp,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 1),
                              borderRadius: BorderRadius.circular(20),
                              color: colorScheme.primary.withAlpha(40),
                            ),
                            child: Text(
                              tx['title']
                                  .toString()
                                  .replaceAll('Transaction', '')
                                  .trim(),
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.normal.small(),
                            ),
                          ),
                        ],
                      ),
                      iconColor: colorScheme.primary,
                      collapsedIconColor: colorScheme.onSurface.withOpacity(
                        0.5,
                      ),
                      children: [
                        TransactionReviewCard(
                          onEdit: () {
                            ref
                                .read(mfTransFormProvider.notifier)
                                .editTransaction(index);
                          },
                          onDelete: () async {
                            final shouldDelete =
                                await showDeleteConfirmationDialog(
                                  context,
                                  tx['title'] as String,
                                );
                            if (shouldDelete == true) {
                              ref
                                  .read(mfTransFormProvider.notifier)
                                  .deleteTransaction(index);
                            }
                          },
                          title: tx['title'] as String,
                          data: tx['data'] as Map<String, dynamic>,
                        ),
                      ],
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 16.sdp,
                        endIndent: 16.sdp,
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
