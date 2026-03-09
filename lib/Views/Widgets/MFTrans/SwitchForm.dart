// lib/Views/Widgets/MFTrans/SwitchForm.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class SwitchForm extends ConsumerStatefulWidget {
  const SwitchForm({Key? key}) : super(key: key);

  @override
  ConsumerState<SwitchForm> createState() => _SwitchFormState();
}

class _SwitchFormState extends ConsumerState<SwitchForm> {
  late TextEditingController _amountCtrl;
  late TextEditingController _amcNameCtrl;
  late TextEditingController _fromSchemeCtrl;
  late TextEditingController _toSchemeCtrl;

  @override
  void initState() {
    super.initState();
    // 1. Grab existing Switch state to pre-fill the form when editing a draft
    final state = ref.read(mfTransFormProvider).switchTab;

    _amountCtrl = TextEditingController(text: state.amount);
    _amcNameCtrl = TextEditingController(text: state.amcName);
    _fromSchemeCtrl = TextEditingController(text: state.fromScheme);
    _toSchemeCtrl = TextEditingController(text: state.toScheme);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amcNameCtrl.dispose();
    _fromSchemeCtrl.dispose();
    _toSchemeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mfTransFormProvider).switchTab;
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isAmount = s.unitAmountType == 'Amount in next question';
    final isUnitInput = s.unitAmountType == 'Units in next question';

    return Column(
      key: const ValueKey('SwitchForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MfDropdown(
          label: 'Transaction Units / Amount',
          value: s.unitAmountType,
          items: MfTransFormOptions.switchUnitsAmount,
          onChanged: (v) => notifier.updateSwitch('unitAmountType', v),
        ),
        const FormSpacer(),

        if (isAmount || isUnitInput) ...[
          MfTextInput(
            label: isAmount ? 'Amount (₹)' : 'Number of Units',
            isNumber: true,
            controller: _amountCtrl, // <-- 2. Attach controller
            onChanged: (v) => notifier.updateSwitch('amount', v),
          ),
          const FormSpacer(),
        ],

        MfTextInput(
          label: 'AMC Name',
          controller: _amcNameCtrl, // <-- 2. Attach controller
          onChanged: (v) => notifier.updateSwitch('amcName', v),
        ),
        const FormSpacer(),

        MfTextInput(
          label: 'From Scheme',
          controller: _fromSchemeCtrl, // <-- 2. Attach controller
          onChanged: (v) => notifier.updateSwitch('fromScheme', v),
        ),
        const FormSpacer(),

        MfSingleSelectChips(
          label: 'From Scheme Option',
          value: s.fromSchemeOption,
          items: MfTransFormOptions.schemeOption,
          onChanged: (v) => notifier.updateSwitch('fromSchemeOption', v),
        ),
        const FormSpacer(),

        MfTextInput(
          label: 'To Scheme',
          controller: _toSchemeCtrl, // <-- 2. Attach controller
          onChanged: (v) => notifier.updateSwitch('toScheme', v),
        ),
        const FormSpacer(),

        MfSingleSelectChips(
          label: 'To Scheme Option',
          value: s.toSchemeOption,
          items: MfTransFormOptions.schemeOption,
          onChanged: (v) => notifier.updateSwitch('toSchemeOption', v),
        ),
        const FormSpacer(),

        MfDropdown(
          label: 'Folio',
          value: s.folio,
          items: MfTransFormOptions.folioOptionsWithNew,
          onChanged: (v) => notifier.updateSwitch('folio', v),
        ),
        const FormSpacer(),
      ],
    );
  }
}
