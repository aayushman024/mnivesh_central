import 'package:flutter/material.dart';

import '../Models/moduleScreen_data.dart';
import '../Themes/AppTextStyle.dart';
import 'Dimensions.dart';

class ModuleHeroScreen extends StatefulWidget {
  final ModuleItem item;

  const ModuleHeroScreen({super.key, required this.item});

  @override
  State<ModuleHeroScreen> createState() => _ModuleHeroScreenState();
}

class _ModuleHeroScreenState extends State<ModuleHeroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _contentController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => widget.item.targetScreen!,
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (ctx, anim, _, child) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: Curves.easeInOut,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure SizeUtil is initialised for this screen's dimensions.
    SizeUtil.init(context);

    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Hero(
        tag: 'module_card_${item.title}',
        flightShuttleBuilder: (_, anim, __, fromCtx, ___) {
          final isDarkFrom = Theme.of(fromCtx).brightness == Brightness.dark;
          return Material(
            color: isDarkFrom ? const Color(0xFF0F1115) : Colors.white,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(28.sdp),
                decoration: BoxDecoration(
                  color: isDarkFrom
                      ? item.baseColor.withOpacity(0.15)
                      : item.baseColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28.sdp),
                ),
                child: Icon(item.icon, color: item.baseColor, size: 56.sdp),
              ),
            ),
          );
        },
        child: Material(
          color: bg,
          child: Stack(
            children: [
              // Icon locked to true center — isolated from text layout.
              Center(
                child: Container(
                  padding: EdgeInsets.all(28.sdp),
                  decoration: BoxDecoration(
                    color: isDark
                        ? item.baseColor.withOpacity(0.15)
                        : item.baseColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28.sdp),
                  ),
                  child: Icon(item.icon, color: item.baseColor, size: 56.sdp),
                ),
              ),

              // Text fades in on its own layer — cannot affect icon position.
              Align(
                alignment: const Alignment(0, 0.45),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.sdp),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyle.extraBold.large(
                            isDark ? Colors.white : const Color(0xFF0F1115),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.sdp),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.normal
                              .small(
                                isDark
                                    ? Colors.white60
                                    : Colors.black.withOpacity(0.5),
                              )
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
