import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../../Themes/AppTextStyle.dart';

class NeumorphicModuleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const NeumorphicModuleButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    /// USE YOUR APP THEME COLORS
    final surfaceColor = theme.colorScheme.surface;   // #0F172A in dark
    final baseColor = theme.scaffoldBackgroundColor;  // #020617 in dark

    final outerBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.04);

    final iconBorder = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.06);

    final iconColor = isDark ? Colors.white : Colors.black87;

    final textColor = isDark
        ? Colors.white.withOpacity(0.95)
        : Colors.black87;

    return NeumorphicButton(
      onPressed: onTap,

      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 16,
      ),

      style: NeumorphicStyle(
        color: surfaceColor, // FIXED: uses theme surface

        depth: isDark ? 3 : 2,
        intensity: 0.4,

        boxShape: NeumorphicBoxShape.roundRect(
          BorderRadius.circular(22),
        ),

        border: NeumorphicBorder(
          isEnabled: true,
          color: outerBorder,
          width: 1,
        ),

        /// tuned specifically for your dark colors
        shadowDarkColor: Colors.black.withOpacity(0.8),

        shadowLightColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,

        lightSource: LightSource.topLeft,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// ICON CONTAINER
          Neumorphic(
            style: NeumorphicStyle(
              color: baseColor, // darker than card = correct contrast

              shape: NeumorphicShape.convex,

              depth: isDark ? 2 : -2,

              boxShape: const NeumorphicBoxShape.circle(),

              border: NeumorphicBorder(
                isEnabled: true,
                color: iconBorder,
                width: 1,
              ),

              shadowDarkColor: Colors.black.withOpacity(0.8),

              shadowLightColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,

              lightSource: LightSource.topLeft,
            ),

            padding: const EdgeInsets.all(18),

            child: Icon(
              icon,
              size: 26,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyle.bold.normal().copyWith(
              fontSize: 13.5,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}