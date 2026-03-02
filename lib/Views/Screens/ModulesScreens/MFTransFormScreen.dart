import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

// --- STATE MANAGEMENT ---
enum FormTab { purchaseRedemption, switchTrans, systematic }

class MfTransFormState {
  final FormTab activeTab;

  // Purchase / Redemption
  final String purchRedempTraxType;
  final String purchRedempUnitAmountType;
  final String purchRedempSchemeOption; // ← ADDED (was missing)
  final String purchRedempPaymentMode;

  // Switch
  final String switchUnitAmountType;
  final String switchFromSchemeOption; // ← ADDED (was missing)
  final String switchToSchemeOption;   // ← ADDED (was missing)

  // Systematic
  final String sysTraxType;
  final String sysTraxFor;
  final String sysSchemeOption;  // ← ADDED (was missing)
  final String sysFrequency;     // ← ADDED (was hardcoded)
  final String sysDate;          // ← ADDED (sip_stp_swpDate, was missing)
  final String sysPaymentMode;

  MfTransFormState({
    this.activeTab = FormTab.purchaseRedemption,
    this.purchRedempTraxType = 'Purchase',
    this.purchRedempUnitAmountType = 'Amount in next question',
    this.purchRedempSchemeOption = 'Growth',
    this.purchRedempPaymentMode = 'Netbanking',
    this.switchUnitAmountType = 'Amount in next question',
    this.switchFromSchemeOption = 'Growth',
    this.switchToSchemeOption = 'Growth',
    this.sysTraxType = 'SIP',
    this.sysTraxFor = 'Registration',
    this.sysSchemeOption = 'Growth',
    this.sysFrequency = 'Monthly',
    this.sysDate = '',
    this.sysPaymentMode = 'Netbanking',
  });

  MfTransFormState copyWith({
    FormTab? activeTab,
    String? purchRedempTraxType,
    String? purchRedempUnitAmountType,
    String? purchRedempSchemeOption,
    String? purchRedempPaymentMode,
    String? switchUnitAmountType,
    String? switchFromSchemeOption,
    String? switchToSchemeOption,
    String? sysTraxType,
    String? sysTraxFor,
    String? sysSchemeOption,
    String? sysFrequency,
    String? sysDate,
    String? sysPaymentMode,
  }) {
    return MfTransFormState(
      activeTab: activeTab ?? this.activeTab,
      purchRedempTraxType: purchRedempTraxType ?? this.purchRedempTraxType,
      purchRedempUnitAmountType: purchRedempUnitAmountType ?? this.purchRedempUnitAmountType,
      purchRedempSchemeOption: purchRedempSchemeOption ?? this.purchRedempSchemeOption,
      purchRedempPaymentMode: purchRedempPaymentMode ?? this.purchRedempPaymentMode,
      switchUnitAmountType: switchUnitAmountType ?? this.switchUnitAmountType,
      switchFromSchemeOption: switchFromSchemeOption ?? this.switchFromSchemeOption,
      switchToSchemeOption: switchToSchemeOption ?? this.switchToSchemeOption,
      sysTraxType: sysTraxType ?? this.sysTraxType,
      sysTraxFor: sysTraxFor ?? this.sysTraxFor,
      sysSchemeOption: sysSchemeOption ?? this.sysSchemeOption,
      sysFrequency: sysFrequency ?? this.sysFrequency,
      sysDate: sysDate ?? this.sysDate,
      sysPaymentMode: sysPaymentMode ?? this.sysPaymentMode,
    );
  }
}

class MfTransFormNotifier extends StateNotifier<MfTransFormState> {
  MfTransFormNotifier() : super(MfTransFormState());

  void setTab(FormTab tab) => state = state.copyWith(activeTab: tab);

  void updatePurchRedemp(String key, String val) {
    if (key == 'traxType') {
      // Reset unit/amount type when switching between Purchase and Redemption
      state = state.copyWith(
        purchRedempTraxType: val,
        purchRedempUnitAmountType: 'Amount in next question',
      );
    }
    if (key == 'unitAmountType') state = state.copyWith(purchRedempUnitAmountType: val);
    if (key == 'schemeOption') state = state.copyWith(purchRedempSchemeOption: val);
    if (key == 'paymentMode') state = state.copyWith(purchRedempPaymentMode: val);
  }

  void updateSwitch(String key, String val) {
    if (key == 'unitAmountType') state = state.copyWith(switchUnitAmountType: val);
    if (key == 'fromSchemeOption') state = state.copyWith(switchFromSchemeOption: val);
    if (key == 'toSchemeOption') state = state.copyWith(switchToSchemeOption: val);
  }

  void updateSystematic(String key, String val) {
    if (key == 'traxType') {
      String newFor = state.sysTraxFor;
      // Auto-reset 'Pause' if switching away from SIP (only SIP supports Pause)
      if (val != 'SIP' && newFor == 'Pause') newFor = 'Registration';
      state = state.copyWith(sysTraxType: val, sysTraxFor: newFor);
    }
    if (key == 'traxFor') state = state.copyWith(sysTraxFor: val);
    if (key == 'schemeOption') state = state.copyWith(sysSchemeOption: val);
    if (key == 'frequency') state = state.copyWith(sysFrequency: val);
    if (key == 'date') state = state.copyWith(sysDate: val);
    if (key == 'paymentMode') state = state.copyWith(sysPaymentMode: val);
  }
}

final mfTransFormProvider = StateNotifierProvider.autoDispose<MfTransFormNotifier, MfTransFormState>(
      (ref) => MfTransFormNotifier(),
);

// --- SHARED OPTION LISTS (matching OptionListsSlice.js exactly) ---
const List<String> _schemeOptionOptions = ['Growth', 'IDCW / Dividend'];

const List<String> _purchaseTraxUnitsAmountOptions = [
  // purchaseTraxUnits_AmountOptions — Purchase only supports Amount
  'Amount in next question',
];

const List<String> _redemptionTraxUnitsAmountOptions = [
  // redemptionTraxUnits_AmountOptions
  'Amount in next question',
  'Long Term Units',
  'Redeem All Units',
  'Units in next question',
  'Unlocked Units',
];

const List<String> _switchTraxUnitsAmountOptions = [
  // switchTraxUnits_AmountOptions
  'Amount in next question',
  'Long Term Units',
  'Switch All Units',
  'Units in next question',
  'Unlocked Units',
];

const List<String> _frequencyOptions = [
  // frequencyOptions — includes 'Annually' (was missing in Flutter)
  'Daily',
  'Weekly',
  'Monthly',
  'Quarterly',
  'Annually',
];

const List<String> _sipPauseMonthsOptions = [
  // sipPauseMonthsOptions (was wrong in Flutter — had ['1','2',...])
  'Not Applicable',
  '1 Month',
  '2 Months',
  '3 Months',
  '4 Months',
  'Maximum Months',
];

const List<String> _sysPaymentModeOptions = [
  // sysPaymentModeOptions (was truncated in Flutter)
  'Netbanking',
  'Mandate',
  'Cheque',
  'NEFT/RTGS',
  'Zero Balance',
  'UPI',
];

const List<String> _purchPaymentModeOptions = [
  // purchPaymentModeOptions (name was 'Net Banking' in Flutter; correct is 'Netbanking')
  'Netbanking',
  'Mandate',
  'Cheque',
  'NEFT/RTGS',
  'UPI',
];

const List<String> _sipStpSwpDateOptions = [
  // sip_stp_swpDateOptions (was missing in Flutter entirely)
  '1 to 10',
  '11 to 20',
  '21 to 30',
  'Call Client and take dates',
  'STP - SWP - at your comfort Level',
];

// --- MAIN WIDGET ---
class MFTransFormStep2 extends ConsumerWidget {
  const MFTransFormStep2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
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
          )
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.sdp, 24.sdp, 18.sdp, 120.sdp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(context, "Purch / Redemp", FormTab.purchaseRedemption, state.activeTab, notifier),
                  SizedBox(width: 8.sdp),
                  _buildTab(context, "Switch", FormTab.switchTrans, state.activeTab, notifier),
                  SizedBox(width: 8.sdp),
                  _buildTab(context, "Systematic", FormTab.systematic, state.activeTab, notifier),
                ],
              ),
            ),
            SizedBox(height: 24.sdp),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildForm(state.activeTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context,
      String title,
      FormTab tabValue,
      FormTab activeTab,
      MfTransFormNotifier notifier,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = activeTab == tabValue;

    return GestureDetector(
      onTap: () => notifier.setTab(tabValue),
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
            )
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

  Widget _buildForm(FormTab tab) {
    switch (tab) {
      case FormTab.purchaseRedemption:
        return const PurchRedempForm();
      case FormTab.switchTrans:
        return const SwitchForm();
      case FormTab.systematic:
        return const SystematicForm();
    }
  }
}

// ---------------------------------------------------------------------------
// PURCHASE / REDEMPTION FORM
// ---------------------------------------------------------------------------

class PurchRedempForm extends ConsumerWidget {
  const PurchRedempForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isPurchase = state.purchRedempTraxType == 'Purchase';

    // Show amount text-input only when 'Amount in next question'
    final isAmount = state.purchRedempUnitAmountType == 'Amount in next question';
    // Show units text-input only when 'Units in next question'
    // NOTE: for Purchase this can never be true because purchaseTraxUnits_AmountOptions
    // only contains 'Amount in next question' — but we keep the flag for Redemption.
    final isUnitInput = state.purchRedempUnitAmountType == 'Units in next question';

    return Column(
      key: const ValueKey('PurchRedempForm'),
      children: [
        // Transaction Type
        _CustomDropdown(
          label: 'Transaction Type',
          value: state.purchRedempTraxType,
          items: const ['Purchase', 'Redemption'],
          onChanged: (val) => notifier.updatePurchRedemp('traxType', val!),
        ),
        SizedBox(height: 16.sdp),

        // Transaction Units / Amount
        // FIX: Purchase uses purchaseTraxUnits_AmountOptions = ['Amount in next question'] only.
        //      Redemption uses redemptionTraxUnits_AmountOptions.
        _CustomDropdown(
          label: 'Transaction Units / Amount',
          value: state.purchRedempUnitAmountType,
          items: isPurchase
              ? _purchaseTraxUnitsAmountOptions
              : _redemptionTraxUnitsAmountOptions,
          onChanged: (val) => notifier.updatePurchRedemp('unitAmountType', val!),
        ),
        SizedBox(height: 16.sdp),

        // Conditional amount or units input
        if (isAmount || isUnitInput) ...[
          _CustomTextInput(
            label: isAmount ? 'Amount (₹)' : 'Number of Units',
            isNumber: true,
          ),
          SizedBox(height: 16.sdp),
        ],

        // AMC Name
        const _CustomTextInput(label: 'AMC Name'),
        SizedBox(height: 16.sdp),

        // Scheme Name
        const _CustomTextInput(label: 'Scheme Name'),
        SizedBox(height: 16.sdp),

        // FIX: Scheme Option — was MISSING entirely; required in validatePurchRedemp
        _CustomDropdown(
          label: 'Scheme Option',
          value: state.purchRedempSchemeOption,
          items: _schemeOptionOptions,
          onChanged: (val) => notifier.updatePurchRedemp('schemeOption', val!),
        ),
        SizedBox(height: 16.sdp),

        // Folio
        const _CustomTextInput(label: 'Folio'),
        SizedBox(height: 16.sdp),

        // Payment Mode — only for Purchase
        if (isPurchase) ...[
          // FIX: options were ['Net Banking', 'Cheque', 'UPI', 'Mandate', 'NEFT/RTGS']
          //      correct is purchPaymentModeOptions = ['Netbanking', 'Mandate', 'Cheque', 'NEFT/RTGS', 'UPI']
          _CustomDropdown(
            label: 'Payment Mode',
            value: state.purchRedempPaymentMode,
            items: _purchPaymentModeOptions,
            onChanged: (val) => notifier.updatePurchRedemp('paymentMode', val!),
          ),
          SizedBox(height: 16.sdp),

          // Cheque Number — only when Payment Mode is 'Cheque'
          if (state.purchRedempPaymentMode == 'Cheque') ...[
            const _CustomTextInput(label: 'Cheque Number', isNumber: true, maxLength: 6),
            SizedBox(height: 16.sdp),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SWITCH FORM
// ---------------------------------------------------------------------------

class SwitchForm extends ConsumerWidget {
  const SwitchForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isAmount = state.switchUnitAmountType == 'Amount in next question';
    final isUnitInput = state.switchUnitAmountType == 'Units in next question';

    return Column(
      key: const ValueKey('SwitchForm'),
      children: [
        // Transaction Units / Amount
        _CustomDropdown(
          label: 'Transaction Units / Amount',
          value: state.switchUnitAmountType,
          items: _switchTraxUnitsAmountOptions,
          onChanged: (val) => notifier.updateSwitch('unitAmountType', val!),
        ),
        SizedBox(height: 16.sdp),

        // Conditional amount or units input
        if (isAmount || isUnitInput) ...[
          _CustomTextInput(
            label: isAmount ? 'Amount (₹)' : 'Number of Units',
            isNumber: true,
          ),
          SizedBox(height: 16.sdp),
        ],

        // AMC Name
        const _CustomTextInput(label: 'AMC Name'),
        SizedBox(height: 16.sdp),

        // From Scheme
        const _CustomTextInput(label: 'From Scheme'),
        SizedBox(height: 16.sdp),

        // FIX: From Scheme Option — was MISSING; required in validateSwitch
        _CustomDropdown(
          label: 'From Scheme Option',
          value: state.switchFromSchemeOption,
          items: _schemeOptionOptions,
          onChanged: (val) => notifier.updateSwitch('fromSchemeOption', val!),
        ),
        SizedBox(height: 16.sdp),

        // To Scheme
        const _CustomTextInput(label: 'To Scheme'),
        SizedBox(height: 16.sdp),

        // FIX: To Scheme Option — was MISSING; required in validateSwitch
        _CustomDropdown(
          label: 'To Scheme Option',
          value: state.switchToSchemeOption,
          items: _schemeOptionOptions,
          onChanged: (val) => notifier.updateSwitch('toSchemeOption', val!),
        ),
        SizedBox(height: 16.sdp),

        // Folio
        const _CustomTextInput(label: 'Folio'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SYSTEMATIC FORM
// ---------------------------------------------------------------------------

class SystematicForm extends ConsumerWidget {
  const SystematicForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isSIP = state.sysTraxType == 'SIP';
    final isSTP = state.sysTraxType == 'STP';
    final isCapSTP = state.sysTraxType == 'Capital Appreciation STP';
    final isSWP = state.sysTraxType == 'SWP';
    final isCapSWP = state.sysTraxType == 'Capital Appreciation SWP';

    // Frequency + Date shown for SIP/STP/SWP on Registration only
    // (Capital Appreciation variants do not appear in sysTransactionForOptions)
    final showFrequencyAndDate =
        ['SIP', 'STP', 'SWP'].contains(state.sysTraxType) &&
            state.sysTraxFor == 'Registration';

    // Source scheme: STP, Capital Appreciation STP, SWP, Capital Appreciation SWP
    final showSourceScheme = isSTP || isCapSTP || isSWP || isCapSWP;

    // Target scheme: SIP, STP, Capital Appreciation STP
    final showTargetScheme = isSIP || isSTP || isCapSTP;

    // Tenure shown for:
    //   SIP in Registration or Pause
    //   SWP / CapSWP / STP / CapSTP in Registration
    final showTenure =
        (isSIP && ['Registration', 'Pause'].contains(state.sysTraxFor)) ||
            (['SWP', 'Capital Appreciation SWP', 'STP', 'Capital Appreciation STP']
                .contains(state.sysTraxType) &&
                state.sysTraxFor == 'Registration');

    // First Transaction Amount shown for:
    //   SIP in Registration
    //   SWP / CapSWP in Registration
    //   STP / CapSTP in Cancellation
    final showFirstAmount =
        (isSIP && state.sysTraxFor == 'Registration') ||
            (['SWP', 'Capital Appreciation SWP'].contains(state.sysTraxType) &&
                state.sysTraxFor == 'Registration') ||
            (['STP', 'Capital Appreciation STP'].contains(state.sysTraxType) &&
                state.sysTraxFor == 'Cancellation');

    // Amount label
    final amountLabel = isSIP
        ? 'SIP Amount'
        : ['SWP', 'Capital Appreciation SWP'].contains(state.sysTraxType)
        ? 'SWP Amount'
        : 'STP Amount';

    return Column(
      key: const ValueKey('SystematicForm'),
      children: [
        // Transaction Type
        // FIX: transactionTypeOptions order = ['Capital Appreciation STP', 'Capital Appreciation SWP', 'SIP', 'STP', 'SWP']
        //      Kept user-friendly order here but all 5 options are present.
        _CustomDropdown(
          label: 'Transaction Type',
          value: state.sysTraxType,
          items: const [
            'SIP',
            'STP',
            'Capital Appreciation STP',
            'SWP',
            'Capital Appreciation SWP',
          ],
          onChanged: (val) => notifier.updateSystematic('traxType', val!),
        ),
        SizedBox(height: 16.sdp),

        // Transaction For
        // sysTransactionForOptionsWithPause for SIP, sysTransactionForOptions for others
        _CustomDropdown(
          label: 'Transaction For',
          value: state.sysTraxFor,
          items: isSIP
              ? const ['Registration', 'Pause', 'Cancellation']
              : const ['Registration', 'Cancellation'],
          onChanged: (val) => notifier.updateSystematic('traxFor', val!),
        ),
        SizedBox(height: 16.sdp),

        // Frequency — only for SIP/STP/SWP on Registration
        // FIX: was hardcoded to 'Monthly'; now stateful.
        // FIX: frequencyOptions includes 'Annually' (was missing).
        if (showFrequencyAndDate) ...[
          _CustomDropdown(
            label: 'Frequency',
            value: state.sysFrequency,
            items: _frequencyOptions,
            onChanged: (val) => notifier.updateSystematic('frequency', val!),
          ),
          SizedBox(height: 16.sdp),

          // FIX: SIP/STP/SWP Date — was MISSING entirely
          _CustomDropdown(
            label: 'SIP / STP / SWP Date',
            value: state.sysDate.isEmpty ? _sipStpSwpDateOptions.first : state.sysDate,
            items: _sipStpSwpDateOptions,
            onChanged: (val) => notifier.updateSystematic('date', val!),
          ),
          SizedBox(height: 16.sdp),
        ],

        // AMC Name
        const _CustomTextInput(label: 'AMC Name'),
        SizedBox(height: 16.sdp),

        // Source Scheme (STP / CapSTP / SWP / CapSWP)
        if (showSourceScheme) ...[
          const _CustomTextInput(label: 'Source Scheme'),
          SizedBox(height: 16.sdp),
        ],

        // Target Scheme (SIP / STP / CapSTP)
        if (showTargetScheme) ...[
          const _CustomTextInput(label: 'Target Scheme'),
          SizedBox(height: 16.sdp),
        ],

        // Folio
        const _CustomTextInput(label: 'Folio'),
        SizedBox(height: 16.sdp),

        // FIX: Scheme Option — was MISSING entirely; required in validateSystematic
        _CustomDropdown(
          label: 'Scheme Option',
          value: state.sysSchemeOption,
          items: _schemeOptionOptions,
          onChanged: (val) => notifier.updateSystematic('schemeOption', val!),
        ),
        SizedBox(height: 16.sdp),

        // Amount + Tenure row
        Row(
          children: [
            Expanded(
              child: _CustomTextInput(label: amountLabel, isNumber: true),
            ),
            if (showTenure) ...[
              SizedBox(width: 16.sdp),
              const Expanded(
                child: _CustomTextInput(label: 'Tenure (Months)', isNumber: true),
              ),
            ],
          ],
        ),
        SizedBox(height: 16.sdp),

        // SIP Pause Months — only when Pause + SIP
        // FIX: options were ['1','2','3','4','5','6']
        //      correct is sipPauseMonthsOptions
        if (state.sysTraxFor == 'Pause' && isSIP) ...[
          _CustomDropdown(
            label: 'SIP Pause Months',
            value: _sipPauseMonthsOptions.first,
            items: _sipPauseMonthsOptions,
            onChanged: (v) {},
          ),
          SizedBox(height: 16.sdp),
        ],

        // First Transaction Amount
        if (showFirstAmount) ...[
          const _CustomTextInput(label: 'First Transaction Amount', isNumber: true),
          SizedBox(height: 16.sdp),
        ],

        // Payment Mode + Cheque — only for SIP Registration
        // FIX: options were ['Net Banking', 'Cheque', 'UPI']
        //      correct is sysPaymentModeOptions
        if (isSIP && state.sysTraxFor == 'Registration') ...[
          _CustomDropdown(
            label: 'First Installment Payment Mode',
            value: state.sysPaymentMode,
            items: _sysPaymentModeOptions,
            onChanged: (val) => notifier.updateSystematic('paymentMode', val!),
          ),
          SizedBox(height: 16.sdp),

          if (state.sysPaymentMode == 'Cheque') ...[
            const _CustomTextInput(
              label: 'Cheque Number',
              isNumber: true,
              maxLength: 6,
            ),
            SizedBox(height: 16.sdp),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE UI COMPONENTS (unchanged design language)
// ---------------------------------------------------------------------------

class _CustomTextInput extends StatelessWidget {
  final String label;
  final bool isNumber;
  final int? maxLength;

  const _CustomTextInput({
    required this.label,
    this.isNumber = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
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
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        filled: true,
        counterText: "",
        fillColor:
        theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide:
          BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide:
          BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
        ),
      ),
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      style: AppTextStyle.normal
          .normal(colorScheme.onSurface)
          .copyWith(fontSize: 14.ssp, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyle.normal
            .small(colorScheme.onSurface.withOpacity(0.6))
            .copyWith(fontSize: 13.ssp),
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        filled: true,
        fillColor:
        theme.inputDecorationTheme.fillColor ?? colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide:
          BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide:
          BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.sdp),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5.sdp),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}