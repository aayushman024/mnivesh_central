// lib/Views/Screens/MFTransScreens/MFTransReviewScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';
import '../../Widgets/MFTrans/formComponents.dart';
import 'MFTransScreen.dart'; // import to access mfTransStepProvider

class MFTransFormStep3 extends ConsumerWidget {
  const MFTransFormStep3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formTitle = '';
    Map<String, dynamic> payload = {};

    switch (state.activeTab) {
      case FormTab.purchaseRedemption:
        formTitle = 'Purchase / Redemption';
        payload = notifier.buildPurchRedempPayload();
        break;
      case FormTab.switchTrans:
        formTitle = 'Switch Transaction';
        payload = notifier.buildSwitchPayload();
        break;
      case FormTab.systematic:
        formTitle = 'Systematic Transaction';
        payload = notifier.buildSystematicPayload();
        break;
    }

    // Conditionally combine the current active draft if it has user-entered data
    bool isDirty = false;
    if (state.activeTab == FormTab.purchaseRedemption && state.purchRedemp.amount.isNotEmpty) isDirty = true;
    if (state.activeTab == FormTab.switchTrans && state.switchTab.amount.isNotEmpty) isDirty = true;
    if (state.activeTab == FormTab.systematic && state.systematic.amount.isNotEmpty) isDirty = true;

    final formsToReview = [
      ...state.savedTransactions,
    ];
    if (isDirty) {
      formsToReview.add({'title': formTitle, 'data': payload});
    }

    return Container(
      key: const ValueKey('step3'),
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
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.sdp, 24.sdp, 18.sdp, 120.sdp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Details',
              style: AppTextStyle.extraBold
                  .normal(colorScheme.onSurface)
                  .copyWith(fontSize: 18.ssp),
            ),
            SizedBox(height: 16.sdp),

            ...formsToReview.asMap().entries.map((entry) {
              final index = entry.key;
              final form = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 16.sdp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.sdp,
                        vertical: 6.sdp,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(20),
                        color: colorScheme.primary.withAlpha(40),
                      ),
                      child: Text(
                        'Transaction ${index + 1}',
                        style: AppTextStyle.extraBold.small(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 15.sdp),
                    TransactionReviewCard(
                      onEdit: () {
                        notifier.editTransaction(index);
                        ref.read(mfTransStepProvider.notifier).state = 2;
                      },
                      onDelete: () async {
                        final shouldDelete = await showDeleteConfirmationDialog(
                          context,
                          form['title'] as String,
                        );
                        if (shouldDelete == true) {
                          notifier.deleteTransaction(index);
                        }
                        ref.read(mfTransStepProvider.notifier).state = 2;
                      },
                      title: form['title'] as String,
                      data: form['data'] as Map<String, dynamic>,
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 10.sdp),

            SizedBox(
              width: double.infinity,
              height: 48.sdp,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.sdp),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Save draft to array and route back to step 2
                  notifier.saveCurrentTransactionAndReset();
                  ref.read(mfTransStepProvider.notifier).state = 2;
                },
                icon: PhosphorIcon(
                  PhosphorIcons.plusCircle(),
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  'Add New Transaction',
                  style: AppTextStyle.extraBold
                      .normal(colorScheme.onPrimary)
                      .copyWith(fontSize: 14.ssp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted and made public so we can reuse it in the accordion
class TransactionReviewCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionReviewCard({
    super.key,
    required this.title,
    required this.data,
    this.onEdit,
    this.onDelete,
  });

  String _formatKey(String key) {
    final result = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withAlpha(50),
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(color: colorScheme.onSurface.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              PhosphorIcon(
                PhosphorIcons.fileText(),
                color: colorScheme.primary,
                size: 20.sdp,
              ),
              SizedBox(width: 8.sdp),
              Text(
                title,
                style: AppTextStyle.extraBold
                    .normal(colorScheme.primary)
                    .copyWith(fontSize: 15.ssp),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: PhosphorIcon(
                    PhosphorIcons.pencilSimple(),
                    color: colorScheme.primary,
                    size: 20.sdp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: PhosphorIcon(
                    PhosphorIcons.trash(),
                    color: colorScheme.error,
                    size: 20.sdp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.sdp),
            child: Divider(
              height: 1,
              color: colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          ...data.entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: 12.sdp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatKey(entry.key),
                      style: AppTextStyle.normal
                          .small(colorScheme.onSurface.withOpacity(0.6))
                          .copyWith(fontSize: 12.ssp),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value.toString().isEmpty
                          ? '-'
                          : entry.value.toString(),
                      style: AppTextStyle.normal
                          .normal(colorScheme.onSurface)
                          .copyWith(
                            fontSize: 13.ssp,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
