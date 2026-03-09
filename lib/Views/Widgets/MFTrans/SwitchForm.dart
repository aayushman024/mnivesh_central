// lib/Views/MFTransaction/Widgets/switch_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class SwitchForm extends ConsumerWidget {
  const SwitchForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onChanged: (v) => notifier.updateSwitch('amount', v),
          ),
          const FormSpacer(),
        ],

        MfTextInput(
          label: 'AMC Name',
          onChanged: (v) => notifier.updateSwitch('amcName', v),
        ),
        const FormSpacer(),

        MfTextInput(
          label: 'From Scheme',
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
          onChanged: (v) => notifier.updateSystematic('folio', v),
        ),
        const FormSpacer(),
      ],
    );
  }
}
