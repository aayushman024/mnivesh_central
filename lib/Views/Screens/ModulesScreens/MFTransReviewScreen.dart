// lib/Views/Widgets/MFTrans/mf_trans_form_step3.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';

class MFTransFormStep3 extends ConsumerWidget {
  const MFTransFormStep3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // determine active form payload
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

    // storing forms in a list to future-proof for multi-form cart reviews
    final formsToReview = [
      {'title': formTitle, 'data': payload},
    ];

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
              style: AppTextStyle.bold
                  .normal(colorScheme.onSurface)
                  .copyWith(fontSize: 18.ssp),
            ),
            SizedBox(height: 16.sdp),

            // iterate through forms
            ...formsToReview.map(
              (form) => _ReviewCard(
                title: form['title'] as String,
                data: form['data'] as Map<String, dynamic>,
              ),
            ),

            SizedBox(height: 32.sdp),

            // mock add new transaction button
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
                onPressed: () {},
                icon: PhosphorIcon(
                  PhosphorIcons.plusCircle(),
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  'Add New Transaction',
                  style: AppTextStyle.bold
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

// ─────────────────────────────────────────────
// Form Review Card
// ─────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _ReviewCard({Key? key, required this.title, required this.data})
    : super(key: key);

  // camelCase to spaced Title Case
  String _formatKey(String key) {
    final result = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // filtering out empty values to keep UI clean
    // final filteredData = data.entries
    //     .where((e) => e.value.toString().isNotEmpty)
    //     .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 16.sdp),
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withAlpha(50),
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(color: colorScheme.onSurface.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // form header
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.fileText(),
                color: colorScheme.primary,
                size: 20.sdp,
              ),
              SizedBox(width: 8.sdp),
              Text(
                title,
                style: AppTextStyle.bold
                    .normal(colorScheme.primary)
                    .copyWith(fontSize: 15.ssp),
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

          // payload key-value pairs
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
                      entry.value.isEmpty ? '-' : entry.value.toString(),
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
