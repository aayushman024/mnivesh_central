// lib/Views/MFTransaction/Widgets/purch_redemp_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class PurchRedempForm extends ConsumerWidget {
  const PurchRedempForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mfTransFormProvider).purchRedemp;
    final notifier = ref.read(mfTransFormProvider.notifier);

    final isPurchase = s.traxType == 'Purchase';
    final isAmount = s.unitAmountType == 'Amount in next question';
    final isUnitInput = s.unitAmountType == 'Units in next question';

    return Column(
      key: const ValueKey('PurchRedempForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MfDropdown(
          label: 'Transaction Type',
          value: s.traxType,
          items: MfTransFormOptions.purchaseTraxType,
          onChanged: (v) => notifier.updatePurchRedemp('traxType', v),
        ),
        const FormSpacer(),

        MfDropdown(
          label: 'Transaction Units / Amount',
          value: s.unitAmountType,
          items: isPurchase
              ? MfTransFormOptions.purchaseUnitsAmount
              : MfTransFormOptions.redemptionUnitsAmount,
          onChanged: (v) => notifier.updatePurchRedemp('unitAmountType', v),
        ),
        const FormSpacer(),

        if (isAmount || isUnitInput) ...[
          MfTextInput(
            label: isAmount ? 'Amount (₹)' : 'Number of Units',
            isNumber: true,
            onChanged: (v) => notifier.updatePurchRedemp('amount', v),
          ),
          const FormSpacer(),
        ],

        MfTextInput(
          label: 'AMC Name',
          onChanged: (v) => notifier.updatePurchRedemp('amcName', v),
        ),
        const FormSpacer(),

        MfTextInput(
          label: 'Scheme Name',
          onChanged: (v) => notifier.updatePurchRedemp('schemeName', v),
        ),
        const FormSpacer(),

        MfSingleSelectChips(
          label: 'Scheme Option',
          value: s.schemeOption,
          items: MfTransFormOptions.schemeOption,
          onChanged: (v) => notifier.updatePurchRedemp('schemeOption', v),
        ),
        const FormSpacer(),

        MfTextInput(
          label: 'Folio',
          onChanged: (v) => notifier.updatePurchRedemp('folio', v),
        ),
        const FormSpacer(),

        if (isPurchase) ...[
          MfDropdown(
            label: 'Payment Mode',
            value: s.paymentMode,
            items: MfTransFormOptions.purchPaymentMode,
            onChanged: (v) => notifier.updatePurchRedemp('paymentMode', v),
          ),
          const FormSpacer(),

          if (s.paymentMode == 'Cheque') ...[
            MfTextInput(
              label: 'Cheque Number',
              isNumber: true,
              maxLength: 6,
              onChanged: (v) => notifier.updatePurchRedemp('chequeNumber', v),
            ),
            const FormSpacer(),
          ],
        ],
      ],
    );
  }
}
