import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/mftrans_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class UccCard extends StatelessWidget {
  final UccModel data;
  final String? selectedUccId;
  final Map<String, GlobalKey> cardKeys;
  final void Function(String) onTap;

  const UccCard({
    super.key,
    required this.data,
    required this.selectedUccId,
    required this.cardKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    cardKeys.putIfAbsent(data.id, () => GlobalKey());
    final isSelected = data.id == selectedUccId;
    final overallKycStyle = _kycStyleFor(data.kycStatus, colorScheme);

    final hasJoint1 = data.joint1Name.trim().isNotEmpty && data.joint1Name.trim() != '--';
    final hasJoint2 = data.joint2Name.trim().isNotEmpty && data.joint2Name.trim() != '--';
    final joint1Visual = _kycVisual(data.joint1KycStatus, colorScheme);
    final joint2Visual = _kycVisual(data.joint2KycStatus, colorScheme);

    return Container(
      margin: EdgeInsets.only(bottom: 16.sdp),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: cardKeys[data.id],
            decoration: _cardDecoration(context, isSelected: isSelected),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19.sdp),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => onTap(data.id),
                    child: Padding(
                      padding: EdgeInsets.all(18.sdp),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.sdp),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: PhosphorIcon(
                                  PhosphorIcons.user(PhosphorIconsStyle.fill),
                                  color: colorScheme.primary,
                                  size: 20.sdp,
                                ),
                              ),
                              SizedBox(width: 14.sdp),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.name,
                                      style: AppTextStyle.extraBold
                                          .normal(colorScheme.onSurface)
                                          .copyWith(fontSize: 15.ssp),
                                    ),
                                    SizedBox(height: 2.sdp),
                                    Text(
                                      data.id,
                                      style: AppTextStyle.normal
                                          .small(
                                        colorScheme.onSurface.withValues(
                                          alpha: 0.65,
                                        ),
                                      )
                                          .copyWith(fontSize: 13.ssp),
                                    ),
                                  ],
                                ),
                              ),
                              _KycBadge(
                                label: data.kycLabel,
                                style: overallKycStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 14.sdp),
                          _DashedDivider(color: colorScheme.outlineVariant),
                          SizedBox(height: 14.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol(
                                'Joint 1',
                                data.joint1Name,
                                icon: hasJoint1 ? joint1Visual.icon : null,
                                iconColor: hasJoint1 ? joint1Visual.color : null,
                              ),
                              _InfoCol(
                                'Joint 2',
                                data.joint2Name,
                                icon: hasJoint2 ? joint2Visual.icon : null,
                                iconColor: hasJoint2 ? joint2Visual.color : null,
                              ),
                              _InfoCol('Tax Holding', data.taxHolding),
                            ],
                          ),
                          SizedBox(height: 14.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol(
                                'BSE Status',
                                data.bseStatus,
                                valueColor: data.bseStatus == 'Active'
                                    ? Colors.green.shade700
                                    : colorScheme.error,
                              ),
                              _InfoCol('Bank', data.bank),
                              _InfoCol('Nominee', data.nominee),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ExpandBar(onTap: () => _openDetailsDialog(context)),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: -8.sdp,
              right: -8.sdp,
              child: Container(
                padding: EdgeInsets.all(4.sdp),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: PhosphorIcon(
                  PhosphorIcons.check(PhosphorIconsStyle.bold),
                  color: colorScheme.onPrimary,
                  size: 16.sdp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetailsDialog(BuildContext context) {
    onTap(data.id);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _UccDetailsDialog(data: data),
    );
  }
}

class _UccDetailsDialog extends StatelessWidget {
  final UccModel data;

  const _UccDetailsDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 18.sdp),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.sdp),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.sdp, 14.sdp, 10.sdp, 12.sdp),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.sdp),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'UCC Details',
                      style: AppTextStyle.extraBold.normal(
                        colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: PhosphorIcon(
                      PhosphorIcons.xCircle(PhosphorIconsStyle.bold),
                      color: colorScheme.onSurfaceVariant,
                      size: 22.sdp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.sdp, 8.sdp, 16.sdp, 16.sdp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SoftSection(
                      title: 'Holder KYC',
                      icon: PhosphorIcons.identificationCard(
                        PhosphorIconsStyle.bold,
                      ),
                      child: Column(
                        children: [
                          _KycHolderRow(
                            label: 'Primary',
                            name: data.name,
                            pan: data.primaryPan,
                            status: data.primaryKycStatus,
                          ),
                          _KycHolderRow(
                            label: 'Joint 1',
                            name: data.joint1Name,
                            pan: data.joint1Pan,
                            status: data.joint1KycStatus,
                          ),
                          _KycHolderRow(
                            label: 'Joint 2',
                            name: data.joint2Name,
                            pan: data.joint2Pan,
                            status: data.joint2KycStatus,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.sdp),
                    _SoftSection(
                      title: 'Bank Details',
                      icon: PhosphorIcons.bank(PhosphorIconsStyle.bold),
                      child: data.banks.isEmpty
                          ? const _DetailsMutedText('No bank details available')
                          : Column(
                        children: data.banks
                            .map(
                              (bank) => _DetailRow(
                            title: 'Bank ${bank.index}',
                            value: bank.shortLabel,
                            trailingText: bank.isValid
                                ? 'Valid'
                                : 'Invalid',
                            trailingColor: bank.isValid
                                ? Colors.green
                                : Colors.red,
                          ),
                        )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 12.sdp),
                    _SoftSection(
                      title: 'Nominee',
                      icon: PhosphorIcons.usersThree(PhosphorIconsStyle.bold),
                      child: data.nomineeNames.isEmpty
                          ? const _DetailsMutedText('No nominees available')
                          : Column(
                        children: data.nomineeNames
                            .asMap()
                            .entries
                            .map(
                              (entry) => _DetailRow(
                            title: 'Nominee ${entry.key + 1}',
                            value: entry.value,
                          ),
                        )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 12.sdp),
                    _SoftSection(
                      title: 'BSE Checks',
                      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold),
                      child: Column(
                        children: [
                          _BooleanRow(
                            title: 'Nominee',
                            isValid: data.hasNominee,
                          ),
                          _BooleanRow(
                            title: 'PAN_AD',
                            isValid: data.primaryPanAadhaarValid,
                          ),
                          _BooleanRow(
                            title: 'Bank',
                            isValid: data.anyValidBank,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.sdp),
                    _SoftSection(
                      title: 'Tax / Holding',
                      icon: PhosphorIcons.scales(PhosphorIconsStyle.bold),
                      child: Column(
                        children: [
                          _DetailRow(title: 'Tax', value: data.taxStatusFull),
                          _DetailRow(
                            title: 'Holding',
                            value: data.holdingNatureFull,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 15.sdp),
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 15.sdp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.sdp),
                  ),
                ),
                child: Text(
                 "Close Details",
                  style: AppTextStyle.bold.normal(colorScheme.onPrimary)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandBar extends StatelessWidget {
  final VoidCallback onTap;

  const _ExpandBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFE8F3FF),
        padding: EdgeInsets.symmetric(vertical: 12.sdp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Show all details',
              style: AppTextStyle.extraBold
                  .small(const Color(0xFF0B63CE))
                  .copyWith(fontSize: 13.ssp),
            ),
            SizedBox(width: 6.sdp),
            PhosphorIcon(
              PhosphorIcons.arrowsOutSimple(PhosphorIconsStyle.bold),
              color: const Color(0xFF0B63CE),
              size: 16.sdp,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftSection extends StatelessWidget {
  final String title;
  final PhosphorIconData icon;
  final Widget child;

  const _SoftSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.sdp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.sdp,
            offset: Offset(0, 2.sdp),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, color: colorScheme.primary, size: 16.sdp),
              SizedBox(width: 8.sdp),
              Text(
                title,
                style: AppTextStyle.extraBold
                    .small(colorScheme.onSurface)
                    .copyWith(fontSize: 13.ssp),
              ),
            ],
          ),
          SizedBox(height: 10.sdp),
          child,
        ],
      ),
    );
  }
}

class _KycHolderRow extends StatelessWidget {
  final String label;
  final String name;
  final String pan;
  final UccKycStatus status;

  const _KycHolderRow({
    required this.label,
    required this.name,
    required this.pan,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedName = name.trim().isEmpty ? '--' : name;
    final resolvedPan = pan.trim().isEmpty ? 'N/A' : pan;
    final visual = _kycVisual(status, colorScheme);

    final isJoint = label.toLowerCase().contains('joint');

    return _DetailRow(
      title: label,
      value: '$resolvedName ($resolvedPan)',
      trailingText: isJoint ? null : visual.label,
      trailingColor: visual.color,
      trailingIcon: visual.icon,
    );
  }
}

class _DetailsMutedText extends StatelessWidget {
  final String text;

  const _DetailsMutedText(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTextStyle.normal.small(
        colorScheme.onSurface.withValues(alpha: 0.65),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final String? trailingText;
  final Color? trailingColor;
  final IconData? trailingIcon;

  const _DetailRow({
    required this.title,
    required this.value,
    this.trailingText,
    this.trailingColor,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 6.sdp),
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 9.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10.sdp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.sdp,
            offset: Offset(0, 2.sdp),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title: $value',
              style: AppTextStyle.normal.small(colorScheme.onSurface),
            ),
          ),
          if (trailingText != null || trailingIcon != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingIcon != null)
                  PhosphorIcon(
                    trailingIcon!,
                    color: trailingColor ?? colorScheme.primary,
                    size: 13.sdp,
                  ),
                if (trailingIcon != null && trailingText != null)
                  SizedBox(width: 4.sdp),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: AppTextStyle.bold.small(
                      trailingColor ?? colorScheme.primary,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BooleanRow extends StatelessWidget {
  final String title;
  final bool isValid;

  const _BooleanRow({required this.title, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final visual = isValid
        ? _KycVisual(
      icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      color: Colors.green,
      label: 'Pass',
    )
        : _KycVisual(
      icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
      color: Colors.red,
      label: 'Fail',
    );

    return _DetailRow(
      title: title,
      value: isValid ? 'Valid' : 'Invalid',
      trailingText: visual.label,
      trailingColor: visual.color,
      trailingIcon: visual.icon,
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _InfoCol(
      this.label,
      this.value, {
        this.valueColor,
        this.icon,
        this.iconColor,
      });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.normal
                .small(colorScheme.onSurface.withValues(alpha: 0.65))
                .copyWith(fontSize: 12.ssp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6.sdp),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.normal
                      .custom( 13.ssp, valueColor ?? colorScheme.onSurface)
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 4.sdp),
                Padding(
                  padding: EdgeInsets.only(top: 1.sdp),
                  child: PhosphorIcon(
                    icon!,
                    color: iconColor ?? colorScheme.primary,
                    size: 14.sdp,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final String label;
  final _KycStyle style;

  const _KycBadge({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.sdp, vertical: 6.sdp),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20.sdp),
      ),
      child: Text(
        label,
        style: AppTextStyle.extraBold
            .small(style.foreground)
            .copyWith(fontSize: 12.ssp),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.constrainWidth() / 8.sdp).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
                (_) => SizedBox(
              width: 4.sdp,
              height: 1.sdp,
              child: ColoredBox(color: color.withValues(alpha: 0.5)),
            ),
          ),
        );
      },
    );
  }
}

class _KycStyle {
  final Color background;
  final Color foreground;

  const _KycStyle({required this.background, required this.foreground});
}

class _KycVisual {
  final PhosphorIconData icon;
  final Color color;
  final String label;

  const _KycVisual({
    required this.icon,
    required this.color,
    required this.label,
  });
}

_KycStyle _kycStyleFor(UccKycStatus status, ColorScheme colorScheme) {
  switch (status) {
    case UccKycStatus.validated:
      return _KycStyle(
        background: Colors.green.withValues(alpha: 0.13),
        foreground: Colors.green.shade800,
      );
    case UccKycStatus.registered:
      return _KycStyle(
        background: Colors.orange.withValues(alpha: 0.16),
        foreground: Colors.orange.shade900,
      );
    case UccKycStatus.rejected:
      return _KycStyle(
        background: colorScheme.error.withValues(alpha: 0.13),
        foreground: colorScheme.error,
      );
    case UccKycStatus.checking:
      return _KycStyle(
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurfaceVariant,
      );
  }
}

_KycVisual _kycVisual(UccKycStatus status, ColorScheme colorScheme) {
  switch (status) {
    case UccKycStatus.validated:
      return _KycVisual(
        icon: PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
        color: Colors.green,
        label: 'Verified',
      );
    case UccKycStatus.registered:
      return _KycVisual(
        icon: PhosphorIcons.hourglassHigh(PhosphorIconsStyle.fill),
        color: Colors.orange.shade800,
        label: 'Pending',
      );
    case UccKycStatus.rejected:
      return _KycVisual(
        icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        color: Colors.red,
        label: 'Invalid',
      );
    case UccKycStatus.checking:
      return _KycVisual(
        icon: PhosphorIcons.hourglassHigh(PhosphorIconsStyle.fill),
        color: colorScheme.onSurfaceVariant,
        label: 'Pending',
      );
  }
}

BoxDecoration _cardDecoration(
    BuildContext context, {
      required bool isSelected,
    }) {
  final colorScheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(20.sdp),
    border: Border.all(
      color: isSelected
          ? colorScheme.primary
          : colorScheme.onSurface.withValues(alpha: 0.1),
      width: isSelected ? 1.5.sdp : 1.sdp,
    ),
    boxShadow: [
      BoxShadow(
        color: isSelected ? colorScheme.primary.withAlpha(50) : Colors.black.withAlpha(20),
        blurRadius: 10.sdp,
        spreadRadius: 1.sdp,
      ),
    ],
  );
}