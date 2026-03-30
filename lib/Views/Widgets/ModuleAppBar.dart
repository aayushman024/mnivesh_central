import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';

class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const ModuleAppBar({required this.title, this.bottom, super.key});

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
      backgroundColor:  Colors.transparent,
      elevation:        0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
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
                const Alignment(0, 0.45), // from center lower
                Alignment.centerLeft,     // to appbar left
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
              style: AppTextStyle.extraBold.custom(18.sdp, theme.colorScheme.onSurface)
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Text(
          title,
          style: AppTextStyle.extraBold.custom(18.sdp, theme.colorScheme.onSurface)
        ),
      ),
    ),
      bottom: bottom,
    );
  }
}
