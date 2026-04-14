// lib/Views/Widgets/MFTrans/SwitchForm.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ViewModels/mfTransaction_viewModel.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class SwitchForm extends ConsumerStatefulWidget {
  const SwitchForm({super.key});

  @override
  ConsumerState<SwitchForm> createState() => _SwitchFormState();
}

class _SwitchFormState extends ConsumerState<SwitchForm> {
  late TextEditingController _amountCtrl;
  late TextEditingController _fromSchemeCtrl;

  @override
  void initState() {
    super.initState();
    // 1. Grab existing Switch state to pre-fill the form when editing a draft
    final state = ref.read(mfTransFormProvider).switchTab;

    _amountCtrl = TextEditingController(text: state.amount);
    _fromSchemeCtrl = TextEditingController(text: state.fromScheme);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _fromSchemeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(
      mfTransFormProvider.select((state) => state.switchTab),
    );
    final notifier = ref.read(mfTransFormProvider.notifier);
    final iWellCode = ref.watch(
      mfTransactionProvider.select(
        (state) => state.selectedInvestor?.iWellCode,
      ),
    );

    final isAmount = s.unitAmountType == 'Amount in next question';
    final isUnitInput = s.unitAmountType == 'Units in next question';
    final folioItems = s.folioOptions.contains(s.folio)
        ? s.folioOptions
        : <String>[
            ...s.folioOptions,
            if (s.folio.trim().isNotEmpty) s.folio.trim(),
          ];

    return Column(
      key: const ValueKey('SwitchForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MfSearchInput(
          label: 'AMC Name',
          initialValue: s.amcName,
          searchFunction: notifier.searchAmcNames,
          onChanged: (v) => notifier.updateSwitchAmc(v, iWellCode: iWellCode),
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

        MfSearchInput(
          label: 'To Scheme',
          initialValue: s.toScheme,
          enabled: s.amcName.trim().isNotEmpty,
          searchFunction: (query) =>
              notifier.searchSchemeNames(amc: s.amcName, query: query),
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
          items: folioItems,
          onChanged: (v) => notifier.updateSwitch('folio', v),
        ),
        const FormSpacer(),

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
      ],
    );
  }
}
