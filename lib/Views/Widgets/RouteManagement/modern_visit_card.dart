import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class ModernVisitCard extends StatelessWidget {
  final String name;
  final String feName;
  final String status;
  final String purposeOfVisit;
  final String priority;
  final String? availability;
  final String clientAddress;
  final String visitAddress;
  final DateFormat commentTimeFormat;
  final List<FieldExecutiveComment> feComments;
  final String? addedBy;
  final String? completedAtTimeStr;
  final Widget? actionButtons;

  const ModernVisitCard({
    super.key,
    required this.name,
    required this.feName,
    required this.status,
    required this.purposeOfVisit,
    required this.priority,
    required this.availability,
    required this.clientAddress,
    required this.visitAddress,
    required this.commentTimeFormat,
    required this.feComments,
    this.addedBy,
    this.completedAtTimeStr,
    this.actionButtons,
  });

  static ({Color base, Color onColor, String label, IconData icon})
      _priorityMeta(String priorityStr) {
    final clean = priorityStr.trim().toLowerCase();
    final p = int.tryParse(clean);

    if (p == 0 || p == 1 || clean == 'highest' || clean == '0' || clean == '1') {
      return (
        base: const Color(0xFFEF4444),
        onColor: const Color(0xFFEF4444),
        label: 'Highest',
        icon: PhosphorIcons.caretDoubleUp(),
      );
    } else if (p == 2 || clean == 'high' || clean == '2') {
      return (
        base: const Color(0xFFF97316),
        onColor: const Color(0xFFF97316),
        label: 'High',
        icon: PhosphorIcons.arrowUp(),
      );
    } else if (p == 3 || clean == 'medium' || clean == '3') {
      return (
        base: const Color(0xFFF59E0B),
        onColor: const Color(0xFFB45309),
        label: 'Medium',
        icon: PhosphorIcons.minus(),
      );
    } else if (p == 4 || clean == 'low' || clean == '4') {
      return (
        base: const Color(0xFF22C55E),
        onColor: const Color(0xFF15803D),
        label: 'Low',
        icon: PhosphorIcons.arrowDown(),
      );
    } else if (p == 5 || clean == 'lowest' || clean == '5') {
      return (
        base: const Color(0xFF38BDF8),
        onColor: const Color(0xFF0369A1),
        label: 'Lowest',
        icon: PhosphorIcons.caretDoubleDown(),
      );
    }

    return (
      base: const Color(0xFF94A3B8),
      onColor: const Color(0xFF475569),
      label: (priorityStr.isEmpty || priorityStr == '0') ? 'Highest' : priorityStr,
      icon: PhosphorIcons.flag(),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _priorityMeta(priority);

    return Container(
      margin: EdgeInsets.only(bottom: 4.sdp),
      padding: EdgeInsets.symmetric(vertical: 10.sdp, horizontal: 10.sdp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20.sdp),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 16.sdp,
            offset: Offset(0, 6.sdp),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.sdp, 8.sdp, 16.sdp, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyle.extraBold.custom(
                          16.ssp,
                          colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (feName.trim().isNotEmpty) ...[
                        SizedBox(height: 4.sdp),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.mapPin(),
                              size: 13.sdp,
                              color: colorScheme.primary,
                            ),
                            SizedBox(width: 4.sdp),
                            Flexible(
                              child: Text(
                                feName.trim(),
                                style: AppTextStyle.bold.custom(
                                  12.ssp,
                                  colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (addedBy != null && addedBy!.isNotEmpty) ...[
                        SizedBox(height: 4.sdp),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.userPlus(),
                              size: 13.sdp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.sdp),
                            Flexible(
                              child: Text(
                                'Added by: $addedBy',
                                style: AppTextStyle.normal.custom(
                                  11.ssp,
                                  colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.sdp),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(label: status),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.sdp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sdp),
            child: Wrap(
              spacing: 6.sdp,
              runSpacing: 6.sdp,
              children: [
                PriorityPill(meta: meta, isDark: isDark),
                if (availability != null && availability != '-')
                  TimePill(
                    text: availability!,
                    colorScheme: colorScheme,
                  ),
                if (status.toLowerCase() == 'completed' && completedAtTimeStr != null)
                  CompletedAtPill(
                    time: completedAtTimeStr!,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.sdp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sdp),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14.sdp,
                vertical: 12.sdp,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16.sdp),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8.sdp,
                    offset: Offset(0, 4.sdp),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.sdp),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.clipboardText(),
                      color: colorScheme.primary,
                      size: 14.sdp,
                    ),
                  ),
                  SizedBox(width: 10.sdp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purpose of Visit',
                          style: AppTextStyle.bold.custom(
                            11.ssp,
                            colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 2.sdp),
                        Text(
                          purposeOfVisit,
                          style: AppTextStyle.bold.custom(
                            13.ssp,
                            colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.sdp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sdp),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.sdp),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14.sdp),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: _buildAddressRow(
                PhosphorIcons.mapPin(),
                'Visit Address',
                visitAddress,
                colorScheme,
              ),
            ),
          ),
          if (feComments.isNotEmpty) ...[
            SizedBox(height: 16.sdp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.sdp),
              child: _buildCommentSection('FE Comments', colorScheme, isDark),
            ),
          ],
          SizedBox(height: 14.sdp),
          if (actionButtons != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.sdp, horizontal: 8.sdp),
              child: actionButtons,
            ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
    IconData icon,
    String title,
    String value,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 18.sdp),
            SizedBox(width: 8.sdp),
            Text(
              title,
              style: AppTextStyle.bold.custom(
                14.ssp,
                colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.sdp),
        Text(
          value,
          style: AppTextStyle.normal.custom(15.ssp, colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildCommentSection(String title, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.chatTeardropDots(),
              color: colorScheme.primary,
              size: 18.sdp,
            ),
            SizedBox(width: 8.sdp),
            Text(
              title,
              style: AppTextStyle.bold.custom(
                14.ssp,
                colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.sdp),
        ...feComments.map(
          (comment) => Padding(
            padding: EdgeInsets.only(bottom: 10.sdp),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.sdp),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.sdp),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.text,
                    style: AppTextStyle.normal.custom(
                      14.ssp,
                      colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.sdp),
                  Text(
                    _buildCommentMeta(comment),
                    style: AppTextStyle.normal.custom(
                      11.ssp,
                      colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildCommentMeta(FieldExecutiveComment comment) {
    final parts = <String>[
      comment.byName.trim().isEmpty ? 'Field Executive' : comment.byName.trim(),
    ];
    if (comment.createdAt != null) {
      parts.add(commentTimeFormat.format(comment.createdAt!));
    }
    return parts.join(' • ');
  }
}

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = label.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    final Color backgroundColor;
    final Color textColor;

    if (normalized == 'completed') {
      backgroundColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
    } else if (normalized == 'closed') {
      backgroundColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
    } else if (normalized == 'cancelled') {
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else if (normalized == 'onhold' || normalized == 'hold') {
      backgroundColor = const Color(0xFFFEF9C3);
      textColor = const Color(0xFFB45309);
    } else if (normalized == 'near client') {
      backgroundColor = const Color(0xFFFEF9C3);
      textColor = const Color(0xFFB45309);
    } else if (normalized == 'pending') {
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else {
      backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.8);
      textColor = colorScheme.onPrimaryContainer;
    }

    final displayLabel = label.isEmpty
        ? '-'
        : label[0].toUpperCase() + label.substring(1);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.sdp),
      ),
      child: Text(
        displayLabel,
        style: AppTextStyle.bold.custom(12.ssp, textColor),
      ),
    );
  }
}

class PriorityPill extends StatelessWidget {
  final ({Color base, Color onColor, String label, IconData icon}) meta;
  final bool isDark;

  const PriorityPill({super.key, required this.meta, required this.isDark});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
      decoration: BoxDecoration(
        color: meta.base.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(10.sdp),
        border: Border.all(
          color: meta.base.withValues(alpha: isDark ? 0.35 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 13.sdp, color: meta.onColor),
          SizedBox(width: 5.sdp),
          Text(
            meta.label,
            style: AppTextStyle.bold.custom(11.ssp, meta.onColor),
          ),
        ],
      ),
    );
  }
}

class TimePill extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const TimePill({super.key, required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10.sdp),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.clock(),
            size: 13.sdp,
            color: colorScheme.primary,
          ),
          SizedBox(width: 5.sdp),
          Text(
            text,
            style: AppTextStyle.bold.custom(11.ssp, colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class CompletedAtPill extends StatelessWidget {
  final String time;
  final ColorScheme colorScheme;

  const CompletedAtPill({super.key, required this.time, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10.sdp),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.checkCircle(),
            size: 13.sdp,
            color: const Color(0xFF22C55E),
          ),
          SizedBox(width: 5.sdp),
          Text(
            'Completed at $time',
            style: AppTextStyle.bold.custom(11.ssp, const Color(0xFF22C55E)),
          ),
        ],
      ),
    );
  }
}
