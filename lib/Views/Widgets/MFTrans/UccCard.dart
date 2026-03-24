import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../Models/mftrans_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class UccCard extends StatelessWidget {
  final UccModel data;
  final String? selectedUccId;
  final Map<String, GlobalKey> cardKeys;
  final void Function(String) onTap;

  const UccCard({
    required this.data,
    required this.selectedUccId,
    required this.cardKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    cardKeys.putIfAbsent(data.id, () => GlobalKey());
    final isSelected = data.id == selectedUccId;

    return GestureDetector(
      onTap: () => onTap(data.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.sdp),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              key: cardKeys[data.id],
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20.sdp),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.1),
                  width: isSelected ? 1.5.sdp : 1.sdp,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10.sdp,
                    spreadRadius: 1.sdp,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19.sdp),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(20.sdp),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.06)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.sdp),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: colorScheme.primary,
                              size: 20.sdp,
                            ),
                          ),
                          SizedBox(width: 16.sdp),
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
                                    colorScheme.onSurface.withOpacity(0.6),
                                  )
                                      .copyWith(fontSize: 13.ssp),
                                ),
                              ],
                            ),
                          ),
                          if (data.isValidated)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.sdp,
                                vertical: 6.sdp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.sdp),
                              ),
                              child: Text(
                                'Validated',
                                style: AppTextStyle.extraBold
                                    .small(Colors.green)
                                    .copyWith(fontSize: 12.ssp),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.sdp, 0, 20.sdp, 20.sdp),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final count =
                              (constraints.constrainWidth() / 8.sdp)
                                  .floor();
                              return Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  count,
                                      (_) => SizedBox(
                                    width: 4.sdp,
                                    height: 1.sdp,
                                    child: ColoredBox(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol('Joint 1', '--'),
                              _InfoCol('Joint 2', '--'),
                              _InfoCol('Tax Holding', 'IND / SI'),
                            ],
                          ),
                          SizedBox(height: 16.sdp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoCol(
                                'BSE Status',
                                data.bseStatus,
                                valueColor: data.bseStatus == 'Active'
                                    ? Colors.green
                                    : colorScheme.error,
                              ),
                              _InfoCol('Bank Detail', data.bank),
                              _InfoCol('Nominee', data.nominee),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimary,
                    size: 16.sdp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCol(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.normal
              .small(colorScheme.onSurface.withOpacity(0.6))
              .copyWith(fontSize: 12.ssp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 6.sdp),
        Text(
          value,
          style: AppTextStyle.normal
              .small(valueColor ?? colorScheme.onSurface)
              .copyWith(fontSize: 13.ssp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}