import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';

class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;
  final bool showDiscardAlert;
  final VoidCallback? onDiscard;

  const ModuleAppBar({
    required this.title,
    this.bottom,
    this.showDiscardAlert = false,
    this.onDiscard,
    super.key,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom != null ? 20 : 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          if (showDiscardAlert) {
            _showDiscardDialog(context);
          } else {
            Navigator.of(context).pop();
          }
        },
        icon: PhosphorIcon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
      ),
      title: Hero(
        tag: 'module_title_$title',
        flightShuttleBuilder: (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
            ) {
          final theme = Theme.of(toHeroContext);
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              return Align(
                alignment: Alignment.lerp(
                  const Alignment(0, 0.45),
                  Alignment.centerLeft,
                  curved.value,
                )!,
                child: Transform.scale(
                  scale: lerpDouble(1.2, 1.0, curved.value)!,
                  child: Opacity(
                    opacity: curved.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Text(
                title,
                style: AppTextStyle.extraBold
                    .custom(18.sdp, theme.colorScheme.onSurface),
              ),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Text(
            title,
            style: AppTextStyle.extraBold
                .custom(18.sdp, theme.colorScheme.onSurface),
          ),
        ),
      ),
      bottom: bottom,
    );
  }

  void _showDiscardDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
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
                    style: AppTextStyle.light.normal()
                  ),
                  SizedBox(height: 24.sdp),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Pop dialog, then pop screen. Cache persists.
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          backgroundColor: colorScheme.primary.withAlpha(10),
                          side: BorderSide(color: colorScheme.primary),
                        ),
                        child: Text('Save Draft',
                          style: AppTextStyle.bold.custom(13.ssp),),
                      ),
                      SizedBox(width: 8.sdp),
                      OutlinedButton(
                        onPressed: () {
                          // Trigger the callback to clear viewmodels, then pop.
                          onDiscard?.call();
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          backgroundColor: colorScheme.error.withAlpha(10),
                          side: BorderSide(color: colorScheme.error),
                        ),
                        child: Text('Discard Progress',
                          style: AppTextStyle.bold.custom(13.ssp),),
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
                      'Drafts are stored temporarily and will be lost if the app is closed.',
                      style: AppTextStyle.normal.custom(11.ssp, Colors.blue.shade700)
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
}