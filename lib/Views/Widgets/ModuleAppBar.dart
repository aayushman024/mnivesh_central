import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../Models/moduleScreen_data.dart';
import '../../Providers/module_usage_provider.dart';
import '../../Services/CustomHapticService.dart';
import '../../Services/snackBar_Service.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../Utils/DiscardChangesDialog.dart';

class ModuleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool isBackIcon;
  final PreferredSizeWidget? bottom;
  final bool showDiscardAlert;
  final VoidCallback? onDiscard;

  const ModuleAppBar({
    required this.title,
    this.isBackIcon = false,
    this.bottom,
    this.showDiscardAlert = false,
    this.onDiscard,
    super.key,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom != null ? 20 : 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final module = _findModuleByTitle(title);
    return AppBar(
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () async {
          if (showDiscardAlert) {
            final action = await showModuleDiscardDialog(context);
            if (action == null || !context.mounted) return;

            if (action == ModuleDiscardAction.discardProgress) {
              onDiscard?.call();
            }
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop();
          }
        },
        icon: isBackIcon ? Icon(PhosphorIconsBold.caretLeft) : Icon(PhosphorIconsFill.house),
      ),
      title: Hero(
        tag: 'module_title_$title',
        flightShuttleBuilder:
            (
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
                      child: Opacity(opacity: curved.value, child: child),
                    ),
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    title,
                    style: AppTextStyle.extraBold.custom(
                      18.sdp,
                      theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
        child: Material(
          color: Colors.transparent,
          child: Text(
            title,
            style: AppTextStyle.extraBold.custom(
              18.sdp,
              theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
      actions: module == null
          ? null
          : [
              IconButton(
                onPressed: () {
                  CustomHapticService.medium();
                  final isAlreadyFav = ref.read(favouritesProvider).contains(module.title);
                  ref.read(favouritesProvider.notifier).toggleFavourite(module.title);

                  if (!isAlreadyFav) {
                    SnackbarService.showSuccess('${module.title} added to favourites');
                  }
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    ref.watch(favouritesProvider).contains(module.title)
                        ? PhosphorIconsFill.heart
                        : PhosphorIconsRegular.heart,
                    key: ValueKey<bool>(
                      ref.watch(favouritesProvider).contains(module.title),
                    ),
                    color: ref.watch(favouritesProvider).contains(module.title)
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 22.sdp,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12.sdp),
                child: Hero(
                  tag: 'module_icon_$title',
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                        );

                        return AnimatedBuilder(
                          animation: curved,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.lerp(
                                Alignment.center,
                                Alignment.centerRight,
                                curved.value,
                              )!,
                              child: Transform.scale(
                                scale: lerpDouble(1.0, 0.36, curved.value)!,
                                child: child,
                              ),
                            );
                          },
                          child: _ModuleTitleIcon(module: module),
                        );
                      },
                  child: _ModuleTitleIcon(module: module),
                ),
              ),
            ],
      bottom: bottom,
    );
  }

  ModuleItem? _findModuleByTitle(String moduleTitle) {
    for (final module in appModules) {
      if (module.title == moduleTitle) return module;
    }
    for (final module in subModules) {
      if (module.title == moduleTitle) return module;
    }
    return null;
  }
}

class _ModuleTitleIcon extends StatelessWidget {
  final ModuleItem module;

  const _ModuleTitleIcon({required this.module});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(8.sdp),
        decoration: BoxDecoration(
          color: isDark
              ? module.baseColor.withOpacity(0.15)
              : module.baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.sdp),
        ),
        child: Icon(module.icon, color: module.baseColor, size: 20.sdp),
      ),
    );
  }
}
