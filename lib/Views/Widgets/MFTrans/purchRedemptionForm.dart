// lib/Views/MFTransaction/Widgets/purch_redemp_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ViewModels/mfTransaction_viewModel.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';
import 'formComponents.dart';

class PurchRedempForm extends ConsumerStatefulWidget {
  const PurchRedempForm({super.key});

  @override
  ConsumerState<PurchRedempForm> createState() => _PurchRedempFormState();
}

class _PurchRedempFormState extends ConsumerState<PurchRedempForm> {
  late TextEditingController _amountCtrl;
  late TextEditingController _chequeCtrl;

  @override
  void initState() {
    super.initState();
    // 1. Grab existing state to pre-fill the form when editing a draft
    final state = ref.read(mfTransFormProvider).purchRedemp;

    _amountCtrl = TextEditingController(text: state.amount);
    _chequeCtrl = TextEditingController(text: state.chequeNumber);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _chequeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(
      mfTransFormProvider.select((state) => state.purchRedemp),
    );
    final notifier = ref.read(mfTransFormProvider.notifier);
    final iWellCode = ref.watch(
      mfTransactionProvider.select(
        (state) => state.selectedInvestor?.iWellCode,
      ),
    );

    final isPurchase = s.traxType == 'Purchase';
    final isAmount = s.unitAmountType == 'Amount in next question';
    final isUnitInput = s.unitAmountType == 'Units in next question';
    final folioItems = s.folioOptions.contains(s.folio)
        ? s.folioOptions
        : <String>[
            ...s.folioOptions,
            if (s.folio.trim().isNotEmpty) s.folio.trim(),
          ];

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

        MfSearchInput(
          label: 'AMC Name',
          initialValue: s.amcName,
          searchFunction: notifier.searchAmcNames,
          onChanged: (v) =>
              notifier.updatePurchRedempAmc(v, iWellCode: iWellCode),
        ),
        const FormSpacer(),

        MfSearchInput(
          label: 'Scheme Name',
          initialValue: s.schemeName,
          enabled: s.amcName.trim().isNotEmpty,
          searchFunction: (query) =>
              notifier.searchSchemeNames(amc: s.amcName, query: query),
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

        MfDropdown(
          label: 'Folio',
          value: s.folio,
          items: folioItems,
          onChanged: (v) =>
              notifier.updatePurchRedemp('folio', v), // <-- Fixed typo here
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
            controller: _amountCtrl, // <-- 2. Pass controller
            onChanged: (v) => notifier.updatePurchRedemp('amount', v),
          ),
          const FormSpacer(),
        ],

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
              controller: _chequeCtrl,
              // <-- 2. Pass controller
              onChanged: (v) => notifier.updatePurchRedemp('chequeNumber', v),
            ),
            const FormSpacer(),
          ],
        ],
      ],
    );
  }
}
