// lib/Views/MFTransaction/Widgets/mf_trans_form_step2.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../../ViewModels/mfTransForm_viewModel.dart';
import '../../Widgets/MFTrans/SwitchForm.dart';
import '../../Widgets/MFTrans/SystematicForm.dart';
import '../../Widgets/MFTrans/purchRedemptionForm.dart';

class MFTransFormStep2 extends ConsumerStatefulWidget {
  const MFTransFormStep2({super.key});

  @override
  ConsumerState<MFTransFormStep2> createState() => _MFTransFormStep2State();
}

class _MFTransFormStep2State extends ConsumerState<MFTransFormStep2> {
  final Map<FormTab, GlobalKey> _tabKeys = {
    FormTab.systematic: GlobalKey(),
    FormTab.purchaseRedemption: GlobalKey(),
    FormTab.switchTrans: GlobalKey(),
  };

  void _scrollToCenter(FormTab tab) {
    final key = _tabKeys[tab];
    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.5, // 0.5 = center
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mfTransFormProvider);
    final notifier = ref.read(mfTransFormProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const ValueKey('step2'),
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
            // ── Tab Bar ─────────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                spacing: 8.sdp,
                children: [
                  _TabChip(
                    key: _tabKeys[FormTab.systematic],
                    title: 'Systematic',
                    tabValue: FormTab.systematic,
                    activeTab: state.activeTab,
                    onTap: () {
                      notifier.setTab(FormTab.systematic);
                      _scrollToCenter(FormTab.systematic);
                    },
                  ),
                  _TabChip(
                    key: _tabKeys[FormTab.purchaseRedemption],
                    title: 'Purchase/Redemption',
                    tabValue: FormTab.purchaseRedemption,
                    activeTab: state.activeTab,
                    onTap: () {
                      notifier.setTab(FormTab.purchaseRedemption);
                      _scrollToCenter(FormTab.purchaseRedemption);
                    },
                  ),
                  _TabChip(
                    key: _tabKeys[FormTab.switchTrans],
                    title: 'Switch',
                    tabValue: FormTab.switchTrans,
                    activeTab: state.activeTab,
                    onTap: () {
                      notifier.setTab(FormTab.switchTrans);
                      _scrollToCenter(FormTab.switchTrans);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sdp),

            // ── Form Body ───────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildForm(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(MfTransFormState state) {
    switch (state.activeTab) {
      case FormTab.purchaseRedemption:
        return PurchRedempForm(
          key: ValueKey('purch_${state.purchRedempResetKey}'),
        );
      case FormTab.switchTrans:
        return SwitchForm(key: ValueKey('switch_${state.switchResetKey}'));
      case FormTab.systematic:
        return SystematicForm(key: ValueKey('sys_${state.systematicResetKey}'));
    }
  }
}

// ─────────────────────────────────────────────
// Tab Chip
// ─────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String title;
  final FormTab tabValue;
  final FormTab activeTab;
  final VoidCallback onTap;

  const _TabChip({
    super.key,
    required this.title,
    required this.tabValue,
    required this.activeTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = activeTab == tabValue;

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
