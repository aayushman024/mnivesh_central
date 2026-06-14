import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import 'edit_task_bottom_sheet.dart';
import 'modern_visit_card.dart';
import 'visit_details_components.dart';

class AssignedVisitCard extends StatelessWidget {
  final AssignedVisitDetails visit;
  final RouteOptimizationViewModel viewModel;
  final DateFormat dateTimeFormat;

  const AssignedVisitCard({
    super.key,
    required this.visit,
    required this.viewModel,
    required this.dateTimeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final completedAt = visit.completedAtTime != null
        ? dateTimeFormat.format(visit.completedAtTime!)
        : null;
    final updatedAtStr = visit.updatedAt != null
        ? dateTimeFormat.format(visit.updatedAt!)
        : null;
    final nearClientAt = visit.nearClientAtTime != null
        ? dateTimeFormat.format(visit.nearClientAtTime!)
        : null;

    return ModernVisitCard(
      name: visit.client.name,
      feName: visit.feName,
      status: visit.status,
      purposeOfVisit: visit.purposeOfVisit,
      priority: visit.priority,
      availability: formatVisitSlot(
        visit.slotStart,
        visit.slotEnd,
        dateTimeFormat,
        canGoAnytime: visit.canGoAnytime,
      ),
      clientAddress: visit.client.address,
      visitAddress: visit.visitingAddress,
      additionalAddressDetails: visit.additionalAddressDetails,
      commentTimeFormat: dateTimeFormat,
      feComments: visit.feComments,
      addedBy: visit.addedBy,
      completedAtTimeStr: completedAt,
      completionImages: visit.completionImages,
      updatedAtTimeStr: updatedAtStr,
      nearClientAtTimeStr: nearClientAt,
      actionButtons:
      visit.status.toLowerCase() == 'pending' ?
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: SizedBox(
              height: 44.sdp,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => EditTaskBottomSheet(visit: visit, viewModel: viewModel),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sdp),
                  ),
                ),
                icon: Icon(
                  PhosphorIcons.pencilSimple(),
                  color: Theme.of(context).colorScheme.primary,
                  size: 17.sdp,
                ),
                label: Text(
                  'Edit Task',
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: SizedBox(
              height: 44.sdp,
              child: OutlinedButton.icon(
                onPressed: () => _showCloseConfirmation(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sdp),
                  ),
                ),
                icon: Icon(
                  PhosphorIcons.x(),
                  color: Theme.of(context).colorScheme.error,
                  size: 17.sdp,
                ),
                label: Text(
                  'Close Task',
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ) : null,
    );
  }

  void _showCloseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Task?'),
        content: const Text('Are you sure you want to close this task? This action will remove it from the pending list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.closeTask(
                visitId: visit.id,
                onSuccess: () => SnackbarService.showSuccess('Task closed successfully'),
                onError: (msg) => SnackbarService.showError(msg),
              );
            },
            child: const Text('Close Task', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class OnHoldVisitCard extends StatelessWidget {
  final OnHoldVisitDetails visit;
  final RouteOptimizationViewModel viewModel;
  final DateFormat dateTimeFormat;

  const OnHoldVisitCard({
    super.key,
    required this.visit,
    required this.viewModel,
    required this.dateTimeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final completedAt = visit.completedAtTime != null
        ? dateTimeFormat.format(visit.completedAtTime!)
        : null;
    final updatedAtStr = visit.updatedAt != null
        ? dateTimeFormat.format(visit.updatedAt!)
        : null;
    final nearClientAt = visit.nearClientAtTime != null
        ? dateTimeFormat.format(visit.nearClientAtTime!)
        : null;

    return ModernVisitCard(
      name: visit.client.name,
      feName: visit.assignedFeName ?? '',
      status: visit.status,
      purposeOfVisit: visit.purposeOfVisit,
      priority: visit.priority,
      availability: formatVisitSlot(
        visit.availabilityStart,
        visit.availabilityEnd,
        dateTimeFormat,
        canGoAnytime: visit.canGoAnytime,
      ),
      clientAddress: visit.client.address,
      visitAddress: visit.visitingAddress,
      additionalAddressDetails: visit.additionalAddressDetails,
      commentTimeFormat: dateTimeFormat,
      feComments: visit.feComments,
      addedBy: visit.addedBy,
      completedAtTimeStr: completedAt,
      completionImages: visit.completionImages,
      updatedAtTimeStr: updatedAtStr,
      nearClientAtTimeStr: nearClientAt,
      actionButtons: Row(
        children: [
          SizedBox(
            height: 44.sdp,
            child: OutlinedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => EditTaskBottomSheet(visit: visit, viewModel: viewModel),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.sdp),
                ),
              ),
              icon: Icon(
                PhosphorIcons.arrowClockwise(),
                color: Theme.of(context).colorScheme.primary,
                size: 17.sdp,
              ),
              label: Text(
                'Re-assign Task',
                style: AppTextStyle.bold.custom(
                  13.ssp,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: SizedBox(
              height: 44.sdp,
              child: OutlinedButton.icon(
                onPressed: () => _showCloseConfirmation(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.sdp),
                  ),
                ),
                icon: Icon(
                  PhosphorIcons.x(),
                  color: Theme.of(context).colorScheme.error,
                  size: 17.sdp,
                ),
                label: Text(
                  'Close Task',
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Task?'),
        content: const Text('Are you sure you want to close this task? This action will remove it from the on-hold list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.closeTask(
                visitId: visit.id,
                onSuccess: () => SnackbarService.showSuccess('Task closed successfully'),
                onError: (msg) => SnackbarService.showError(msg),
              );
            },
            child: const Text('Close Task', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CompletedVisitCard extends StatelessWidget {
  final CompletedVisitDetails visit;
  final DateFormat dateTimeFormat;

  const CompletedVisitCard({super.key, required this.visit, required this.dateTimeFormat});

  @override
  Widget build(BuildContext context) {
    final start = visit.actualVisitStart ?? visit.availabilityStart;
    final end = visit.actualVisitEnd ?? visit.availabilityEnd;
    final completedAt = visit.completedAtTime != null
        ? dateTimeFormat.format(visit.completedAtTime!)
        : null;
    final updatedAtStr = visit.updatedAt != null
        ? dateTimeFormat.format(visit.updatedAt!)
        : null;
    final nearClientAt = visit.nearClientAtTime != null
        ? dateTimeFormat.format(visit.nearClientAtTime!)
        : null;

    return ModernVisitCard(
      name: visit.client.name,
      feName: visit.feName ?? '',
      status: visit.status,
      purposeOfVisit: visit.purposeOfVisit,
      priority: visit.priority,
      availability: formatVisitSlot(
        start,
        end,
        dateTimeFormat,
        canGoAnytime: visit.canGoAnytime,
      ),
      clientAddress: visit.client.address,
      visitAddress: visit.visitingAddress,
      additionalAddressDetails: visit.additionalAddressDetails,
      commentTimeFormat: dateTimeFormat,
      feComments: visit.feComments,
      addedBy: visit.addedBy,
      completedAtTimeStr: completedAt,
      completionImages: visit.completionImages,
      updatedAtTimeStr: updatedAtStr,
      nearClientAtTimeStr: nearClientAt,
      actionButtons: null,
    );
  }
}
