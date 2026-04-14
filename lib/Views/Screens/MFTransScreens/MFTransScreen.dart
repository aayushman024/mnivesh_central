// lib/Views/MFTransaction/mf_transaction_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:mnivesh_central/Utils/DismissKeyboard.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/mftrans_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../Utils/DiscardChangesDialog.dart';
import '../../../ViewModels/mfTransForm_viewModel.dart';
import '../../../ViewModels/mfTransaction_viewModel.dart';
import '../../Widgets/MFTrans/UccCard.dart';
import '../../Widgets/MFTrans/formComponents.dart';
import '../../Widgets/ModuleAppBar.dart';
import 'MFTransCompletedScreen.dart';
import 'MFTransFormScreen.dart';
import 'MFTransReviewScreen.dart';

final mfTransStepProvider = StateProvider<int>((ref) => 1);

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class MfTransactionScreen extends ConsumerStatefulWidget {
  const MfTransactionScreen({super.key});

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
  final GlobalKey _uccSectionHeadingKey = GlobalKey();

  bool _hasUnsavedChanges(MfTransactionState state) =>
      state.selectedUccId != null;

  void _resetMfProviders() {
    ref.invalidate(mfTransFormProvider);
    ref.invalidate(mfTransactionProvider);
    ref.invalidate(mfTransStepProvider);
    _cardKeys.clear();
  }

  void _clearMfTransactionDraft() {
    _resetMfProviders();
  }

  Future<bool> _handleBackNavigation(MfTransactionState state) async {
    // If no changes, allow pop immediately
    if (!_hasUnsavedChanges(state)) return true;

    final action = await showModuleDiscardDialog(context);

    // User tapped outside the dialog to dismiss it. Stay on screen.
    if (action == null) return false;

    if (action == ModuleDiscardAction.discardProgress) {
      // Clear Riverpod memory, then allow pop
      _resetMfProviders();
      return true;
    }

    if (action == ModuleDiscardAction.saveDraft) {
      // Do NOT clear Riverpod memory (keeps draft), just allow pop
      return true;
    }

    return false;
  }

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

  void _scrollToUccSection({bool retryIfMissing = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headingContext = _uccSectionHeadingKey.currentContext;
      if (headingContext != null) {
        Scrollable.ensureVisible(
          headingContext,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
        return;
      }

      if (retryIfMissing) {
        _scrollToUccSection(retryIfMissing: false);
      }
    });
  }

  void _onSearchUccPressed() {
    unawaited(ref.read(mfTransactionProvider.notifier).fetchUccData());
    _scrollToUccSection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mfTransactionProvider);
    final viewModel = ref.read(mfTransactionProvider.notifier);
    final currentStep = ref.watch(mfTransStepProvider);
    final savedTransactions = ref.watch(
      mfTransFormProvider.select((s) => s.savedTransactions),
    );
    final theme = Theme.of(context);

    // Sync autocomplete controllers when investor is auto-selected
    ref.listen(mfTransactionProvider, (prev, next) {
      if (prev?.selectedInvestor != next.selectedInvestor &&
          next.selectedInvestor != null) {
        final inv = next.selectedInvestor!;
        if (_invCtrl?.text != inv.name) _invCtrl?.text = inv.name;
        if (_panCtrl?.text != inv.pan) _panCtrl?.text = inv.pan;
        if (_headCtrl?.text != inv.familyHead) _headCtrl?.text = inv.familyHead;
      }

      if (prev?.isSearchingUcc != true && next.isSearchingUcc) {
        _scrollToUccSection();
      }
    });

    return DismissKeyboard(
      child: PopScope(
        canPop: !_hasUnsavedChanges(state),
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _handleBackNavigation(state);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: ModuleAppBar(
            title: 'MF Transaction Form',
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(10.sdp),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: _StepBar(filled: state.selectedUccId != null),
                    ),
                    SizedBox(width: 10.sdp),
                    Expanded(child: _StepBar(filled: currentStep >= 2)),
                    SizedBox(width: 10.sdp),
                    Expanded(child: _StepBar(filled: currentStep >= 3)),
                  ],
                ),
              ),
            ),
            showDiscardAlert: _hasUnsavedChanges(state),
            onDiscard: _clearMfTransactionDraft,
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    if (currentStep == 2 &&
                        savedTransactions.isNotEmpty)
                      _SavedTransactionsAccordion(
                        transactions: savedTransactions,
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
          onSearchUcc: _onSearchUccPressed,
          uccSectionHeadingKey: _uccSectionHeadingKey,
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
// AppBar Step Indicator
// ─────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final bool filled;

  const _StepBar({required this.filled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 4.sdp,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.sdp),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: filled ? constraints.maxWidth : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2.sdp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Persistent Bottom Bar
// ─────────────────────────────────────────────

class _BottomBar extends ConsumerStatefulWidget {
  final int currentStep;
  final MfTransactionViewModel viewModel;
  final bool Function() onValidateStep1;

  const _BottomBar({
    required this.currentStep,
    required this.viewModel,
    required this.onValidateStep1,
  });

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String leftText = 'Previous';
    String rightText = 'Proceed';
    Color leftFg = colorScheme.onSurface;
    Color leftBg = colorScheme.surface;
    Color leftBorder = colorScheme.onSurface.withOpacity(0.2);
    Color rightBg = colorScheme.primary;
    VoidCallback? onLeft;
    VoidCallback? onRight;

    if (widget.currentStep == 1) {
      leftText = 'Deselect';
      leftFg = colorScheme.error;
      leftBg = colorScheme.error.withAlpha(15);
      leftBorder = Colors.red.shade200;
      onLeft = () => widget.viewModel.deselectUcc();
      onRight = () {
        if (widget.onValidateStep1()) {
          ref.read(mfTransStepProvider.notifier).state = 2;
        }
      };
    } else if (widget.currentStep == 2) {
      final hasSaved = ref.watch(
        mfTransFormProvider.select((s) => s.savedTransactions.isNotEmpty),
      );
      onLeft = hasSaved
          ? null
          : () => ref.read(mfTransStepProvider.notifier).state = 1;
      onRight = () {
        final isValid = ref
            .read(mfTransFormProvider.notifier)
            .validateActiveFormForProceed();
        if (!isValid) {
          return;
        }
        ref.read(mfTransStepProvider.notifier).state = 3;
      };
    } else {
      rightText = 'Submit';
      rightBg = Colors.green;
      onLeft = _isSubmitting
          ? null
          : () => ref.read(mfTransStepProvider.notifier).state = 2;

      onRight = _isSubmitting
          ? null
          : () async {
        setState(() => _isSubmitting = true);

        final step1State = ref.read(mfTransactionProvider);
        final notifier = ref.read(mfTransFormProvider.notifier);

        final isSuccess = await notifier.submitAllTransactions(step1State);

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (isSuccess) {
            // Reset wizard and navigate to success screen
            ref.read(mfTransStepProvider.notifier).state = 1;
            ref.read(mfTransactionProvider.notifier).clearInvestorSelection();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MFTransCompletedScreen(),
              ),
            );
          }
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
              child: _isSubmitting
                  ? SizedBox(
                height: 20.sdp,
                width: 20.sdp,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                rightText,
                style: AppTextStyle.extraBold
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
  final VoidCallback onSearchUcc;
  final GlobalKey uccSectionHeadingKey;

  _Step1({
    super.key,
    required this.state,
    required this.viewModel,
    required this.onInvCtrl,
    required this.onPanCtrl,
    required this.onHeadCtrl,
    required this.onUccSelected,
    required this.cardKeys,
    required this.onPickDateTime,
    required this.onSearchUcc,
    required this.uccSectionHeadingKey,
  });

  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSearchUcc =
        !state.isSearchingUcc && state.selectedInvestor != null;
    final searchButtonColor = canSearchUcc
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.55);
    final shouldShowUccSection = state.showUcc || state.isSearchingUcc;
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
                              value: state.searchAllInvestors,
                              onChanged: (value) {
                                viewModel.setSearchAllInvestors(value ?? true);
                              },
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
                    skipSearchText: state.selectedInvestor?.name,
                    displayString: (o) => o.name,
                    onInitController: onInvCtrl,
                    searchFunction: viewModel.searchByName,
                    onSelected: viewModel.selectInvestor,
                    onCleared: viewModel.clearInvestorSelection,
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
                    skipSearchText: state.selectedInvestor?.pan,
                    displayString: (o) => o.pan,
                    onInitController: onPanCtrl,
                    searchFunction: viewModel.searchByPan,
                    onSelected: viewModel.selectInvestor,
                    onCleared: viewModel.clearInvestorSelection,
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
                    skipSearchText: state.selectedInvestor?.familyHead,
                    displayString: (o) => o.familyHead,
                    onInitController: onHeadCtrl,
                    searchFunction: viewModel.searchByFamilyHead,
                    onSelected: viewModel.selectInvestor,
                    onCleared: viewModel.clearInvestorSelection,
                  ),

                  SizedBox(height: 32.sdp),

                  // ── Search UCC Button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52.sdp,
                    child: ElevatedButton(
                      onPressed: canSearchUcc ? onSearchUcc : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withAlpha(20),
                        disabledBackgroundColor: colorScheme.primary.withAlpha(
                          10,
                        ),
                        foregroundColor: colorScheme.onPrimary,
                        disabledForegroundColor: searchButtonColor,
                        elevation: 0,
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5.sdp,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.sdp),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.magnifyingGlass(
                              PhosphorIconsStyle.bold,
                            ),
                            color: searchButtonColor,
                          ),
                          SizedBox(width: 8.sdp),
                          Text(
                            'Search UCC',
                            style: AppTextStyle.extraBold
                                .normal(searchButtonColor)
                                .copyWith(fontSize: 16.ssp),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── UCC List ─────────────────────────────────────────────
                  if (shouldShowUccSection) ...[
                    SizedBox(height: 18.sdp),
                    Row(
                      key: uccSectionHeadingKey,
                      children: [
                        Text(
                          'Select UCC',
                          style: AppTextStyle.extraBold
                              .normal(colorScheme.onSurface)
                              .copyWith(fontSize: 16.ssp),
                        ),
                        Tooltip(
                          key: _tooltipKey,
                          triggerMode: TooltipTriggerMode.manual,
                          showDuration: const Duration(seconds: 3),

                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                              ),
                            ],
                          ),

                          richMessage: WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendItem(
                                    "KYC Verified",
                                    PhosphorIcons.sealCheck(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    Colors.green,
                                  ),
                                  SizedBox(height: 6),
                                  _legendItem(
                                    "KYC Pending",
                                    PhosphorIcons.hourglassHigh(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    Colors.orange,
                                  ),
                                  SizedBox(height: 6),
                                  _legendItem(
                                    "KYC Invalid",
                                    PhosphorIcons.xCircle(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          child: IconButton(
                            icon: PhosphorIcon(PhosphorIcons.info()),
                            onPressed: () {
                              _tooltipKey.currentState?.ensureTooltipVisible();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.sdp),
                    if (state.isSearchingUcc)
                      ...List.generate(3, (_) => const UccCardSkeleton())
                    else
                      ...state.uccData.map(
                        (data) => UccCard(
                          data: data,
                          selectedUccId: state.selectedUccId,
                          cardKeys: cardKeys,
                          onTap: onUccSelected,
                        ),
                      ),
                    if (!state.isSearchingUcc && state.uccData.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.sdp),
                        child: Text(
                          'No UCC records found for this investor.',
                          style: AppTextStyle.normal.small(
                            colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
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

class _InvestorAutocomplete extends StatefulWidget {
  final String hint;
  final String? skipSearchText;
  final String Function(InvestorModel) displayString;
  final void Function(TextEditingController) onInitController;
  final Future<List<InvestorModel>> Function(String) searchFunction;
  final void Function(InvestorModel) onSelected;
  final VoidCallback onCleared;

  const _InvestorAutocomplete({
    required this.hint,
    this.skipSearchText,
    required this.displayString,
    required this.onInitController,
    required this.searchFunction,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  State<_InvestorAutocomplete> createState() => _InvestorAutocompleteState();
}

class _InvestorAutocompleteState extends State<_InvestorAutocomplete> {
  Timer? _debounceTimer;
  Completer<List<InvestorModel>>? _pendingCompleter;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _completePending(const []);
    super.dispose();
  }

  Future<List<InvestorModel>> _debouncedSearch(String query) {
    _debounceTimer?.cancel();
    _completePending(const []);

    final completer = Completer<List<InvestorModel>>();
    _pendingCompleter = completer;
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) {
        _completePending(const []);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await widget.searchFunction(query);
        if (!completer.isCompleted) {
          completer.complete(results);
        }
      } catch (_) {
        if (!completer.isCompleted) {
          completer.complete(const []);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        if (identical(_pendingCompleter, completer)) {
          _pendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  void _completePending(List<InvestorModel> fallback) {
    final pending = _pendingCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete(fallback);
    }
    _pendingCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Autocomplete<InvestorModel>(
      optionsBuilder: (tev) async {
        if (tev.text.isEmpty) return const [];
        if (widget.skipSearchText != null &&
            tev.text == widget.skipSearchText) {
          return const [];
        }
        return _debouncedSearch(tev.text);
      },
      displayStringForOption: widget.displayString,
      onSelected: widget.onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
        widget.onInitController(ctrl);
        ctrl.addListener(() => setState(() {}));
        return TextFormField(
          controller: ctrl,
          focusNode: focus,
          style: AppTextStyle.normal.normal(colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyle.normal
                .normal(colorScheme.onSurface.withOpacity(0.4))
                .copyWith(fontSize: 14.ssp),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.sdp,
              vertical: 16.sdp,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            suffixIcon: _isLoading
                ? Padding(
              padding: EdgeInsets.all(12.sdp),
              child: SizedBox(
                width: 16.sdp,
                height: 16.sdp,
                child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            ) :(ctrl.text.isNotEmpty)
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        ctrl.clear();
                      });
                      widget.onCleared();
                    },
                    icon: PhosphorIcon(PhosphorIcons.x(), size: 14.ssp),
                  )
                : null,
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
            elevation: 50,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(16.sdp),
            color: theme.cardColor,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 450.sdp,
                maxWidth: MediaQuery.of(ctx).size.width - 48.sdp,
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.sdp),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1.sdp,
                  color: colorScheme.onSurface.withOpacity(0.1),
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
                            style: AppTextStyle.extraBold
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

//saved trax
// ─────────────────────────────────────────────
// Expandable Cart / Saved Transactions Widget
// ─────────────────────────────────────────────

class _SavedTransactionsAccordion extends ConsumerWidget {
  final List<Map<String, dynamic>> transactions;

  const _SavedTransactionsAccordion({required this.transactions});

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
                            style: AppTextStyle.extraBold
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

Widget _legendItem(String text, PhosphorIconData icon, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PhosphorIcon(icon, color: color, size: 20.sdp),
      SizedBox(width: 10.sdp),
      Text(text, style: AppTextStyle.bold.small(Colors.grey[700])),
    ],
  );
}
