import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../Themes/AppTextStyle.dart';
import 'Dimensions.dart';

enum ModuleDiscardAction { saveDraft, discardProgress }

Future<ModuleDiscardAction?> showModuleDiscardDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog<ModuleDiscardAction>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 8,
      // hardEdge ensures the bottom footer doesn't bleed over the rounded corners
      clipBehavior: Clip.hardEdge,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(24.sdp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.sdp),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                        color: colorScheme.error,
                        size: 24.sdp,
                      ),
                    ),
                    SizedBox(width: 16.sdp),
                    Expanded(
                      child: Text(
                        'Unsaved Changes',
                        style: AppTextStyle.bold.large(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.sdp),
                Text(
                  'Are you sure you want to discard your progress? All current changes will be permanently lost.',
                  style: AppTextStyle.light.normal(),
                ),
                SizedBox(height: 24.sdp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(ModuleDiscardAction.saveDraft);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.primary.withAlpha(10),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                      child: Text(
                        'Save Draft',
                        style: AppTextStyle.bold.custom(13.ssp),
                      ),
                    ),
                    SizedBox(width: 8.sdp),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          ctx,
                        ).pop(ModuleDiscardAction.discardProgress);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: colorScheme.error.withAlpha(10),
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: Text(
                        'Discard Progress',
                        style: AppTextStyle.bold.custom(13.ssp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stuck-to-bottom hint footer
          Container(
            color: Colors.blue.withAlpha(20),
            padding: EdgeInsets.symmetric(horizontal: 24.sdp, vertical: 14.sdp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.info(PhosphorIconsStyle.fill),
                  size: 16.sdp,
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: 10.sdp),
                Expanded(
                  child: Text(
                    'Drafts are stored temporarily and will be lost if the app is restarted.',
                    style: AppTextStyle.normal.custom(
                      11.ssp,
                      Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}