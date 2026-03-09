// lib/Views/MFTransaction/Widgets/systematic_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class SystematicForm extends ConsumerStatefulWidget {
  const SystematicForm({Key? key}) : super(key: key);

  @override
  ConsumerState<SystematicForm> createState() => _SystematicFormState();
}

class _SystematicFormState extends ConsumerState<SystematicForm> {
  late TextEditingController _amcNameCtrl;
  late TextEditingController _sourceSchemeCtrl;
  late TextEditingController _targetSchemeCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _firstAmountCtrl;
  late TextEditingController _chequeCtrl;

  @override
  void initState() {
    super.initState();
    // 1. Grab existing Systematic state to pre-fill the form when editing a draft
    final state = ref.read(mfTransFormProvider).systematic;

    _amcNameCtrl = TextEditingController(text: state.amcName);
    _sourceSchemeCtrl = TextEditingController(text: state.sourceScheme);
    _targetSchemeCtrl = TextEditingController(text: state.targetScheme);
    _amountCtrl = TextEditingController(text: state.amount);
    _tenureCtrl = TextEditingController(text: state.tenure);
    _firstAmountCtrl = TextEditingController(
      text: state.firstTransactionAmount,
    );
    _chequeCtrl = TextEditingController(text: state.chequeNumber);
  }

  @override
  void dispose() {
    _amcNameCtrl.dispose();
    _sourceSchemeCtrl.dispose();
    _targetSchemeCtrl.dispose();
    _amountCtrl.dispose();
    _tenureCtrl.dispose();
    _firstAmountCtrl.dispose();
    _chequeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mfTransFormProvider).systematic;
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isSIP = s.traxType == 'SIP';
    final isSTP = s.traxType == 'STP';
    final isCapSTP = s.traxType == 'Capital Appreciation STP';
    final isSWP = s.traxType == 'SWP';
    final isCapSWP = s.traxType == 'Capital Appreciation SWP';

    final showFrequencyAndDate =
        [
          'SIP',
          'STP',
          'SWP',
          'Capital Appreciation STP',
          'Capital Appreciation SWP',
        ].contains(s.traxType) &&
        s.traxFor == 'Registration';

    final showSourceScheme = isSTP || isCapSTP || isSWP || isCapSWP;
    final showTargetScheme = isSIP || isSTP || isCapSTP;

    final showTenure =
        (isSIP && ['Registration', 'Pause'].contains(s.traxFor)) ||
        ([
              'SWP',
              'Capital Appreciation SWP',
              'STP',
              'Capital Appreciation STP',
            ].contains(s.traxType) &&
            s.traxFor == 'Registration');

    final showFirstAmount =
        (isSIP && s.traxFor == 'Registration') ||
        (['SWP', 'Capital Appreciation SWP'].contains(s.traxType) &&
            s.traxFor == 'Registration') ||
        (['STP', 'Capital Appreciation STP'].contains(s.traxType) &&
            s.traxFor == 'Cancellation');

    final amountLabel = isSIP
        ? 'SIP Amount'
        : ['SWP', 'Capital Appreciation SWP'].contains(s.traxType)
        ? 'SWP Amount'
        : 'STP Amount';

    return Column(
      key: const ValueKey('SystematicForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MfDropdown(
          label: 'Transaction Type',
          value: s.traxType,
          items: MfTransFormOptions.systematicTraxType,
          onChanged: (v) => notifier.updateSystematic('traxType', v),
        ),
        const FormSpacer(),

        MfSingleSelectChips(
          label: 'Transaction For',
          value: s.traxFor,
          items: isSIP
              ? MfTransFormOptions.systematicTraxForWithPause
              : MfTransFormOptions.systematicTraxFor,
          onChanged: (v) => notifier.updateSystematic('traxFor', v),
        ),
        const FormSpacer(),

        if (showFrequencyAndDate) ...[
          MfDropdown(
            label: 'Frequency',
            value: s.frequency,
            items: MfTransFormOptions.frequency,
            onChanged: (v) => notifier.updateSystematic('frequency', v),
          ),
          const FormSpacer(),

          MfDatePicker(
            label: 'SIP / STP / SWP Date',
            value: s.date,
            onChanged: (v) => notifier.updateSystematic('date', v),
          ),
          const FormSpacer(),
        ],

        MfTextInput(
          label: 'AMC Name',
          controller: _amcNameCtrl, // <-- 2. Attach controller
          onChanged: (v) => notifier.updateSystematic('amcName', v),
        ),
        const FormSpacer(),

        if (showSourceScheme) ...[
          MfTextInput(
            label: 'Source Scheme',
            controller: _sourceSchemeCtrl, // <-- 2. Attach controller
            onChanged: (v) => notifier.updateSystematic('sourceScheme', v),
          ),
          const FormSpacer(),
        ],

        if (showTargetScheme) ...[
          MfTextInput(
            label: 'Target Scheme',
            controller: _targetSchemeCtrl, // <-- 2. Attach controller
            onChanged: (v) => notifier.updateSystematic('targetScheme', v),
          ),
          const FormSpacer(),
        ],

        MfDropdown(
          label: 'Folio',
          value: s.folio,
          items: MfTransFormOptions.folioOptionsWithNew,
          onChanged: (v) => notifier.updateSystematic('folio', v),
        ),
        const FormSpacer(),

        MfSingleSelectChips(
          label: 'Scheme Option',
          value: s.schemeOption,
          items: MfTransFormOptions.schemeOption,
          onChanged: (v) => notifier.updateSystematic('schemeOption', v),
        ),
        const FormSpacer(),

        // Amount + Tenure row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MfTextInput(
                label: amountLabel,
                isNumber: true,
                controller: _amountCtrl, // <-- 2. Attach controller
                onChanged: (v) => notifier.updateSystematic('amount', v),
              ),
            ),
            if (showTenure) ...[
              SizedBox(width: 16.sdp),
              Expanded(
                child: MfTextInput(
                  label: 'Tenure (Months)',
                  isNumber: true,
                  controller: _tenureCtrl, // <-- 2. Attach controller
                  onChanged: (v) => notifier.updateSystematic('tenure', v),
                ),
              ),
            ],
          ],
        ),
        const FormSpacer(),

        if (s.traxFor == 'Pause' && isSIP) ...[
          MfDropdown(
            label: 'SIP Pause Months',
            value: s.sipPauseMonths,
            items: MfTransFormOptions.sipPauseMonths,
            onChanged: (v) => notifier.updateSystematic('sipPauseMonths', v),
          ),
          const FormSpacer(),
        ],

        if (showFirstAmount) ...[
          MfTextInput(
            label: 'First Transaction Amount',
            isNumber: true,
            controller: _firstAmountCtrl, // <-- 2. Attach controller
            onChanged: (v) =>
                notifier.updateSystematic('firstTransactionAmount', v),
          ),
          const FormSpacer(),
        ],

        if (isSIP && s.traxFor == 'Registration') ...[
          MfDropdown(
            label: 'First Installment Payment Mode',
            value: s.paymentMode,
            items: MfTransFormOptions.sysPaymentMode,
            onChanged: (v) => notifier.updateSystematic('paymentMode', v),
          ),
          const FormSpacer(),

          if (s.paymentMode == 'Cheque') ...[
            MfTextInput(
              label: 'Cheque Number',
              isNumber: true,
              maxLength: 6,
              controller: _chequeCtrl,
              // <-- 2. Attach controller
              onChanged: (v) => notifier.updateSystematic('chequeNumber', v),
            ),
            const FormSpacer(),
          ],
        ],
      ],
    );
  }
}
