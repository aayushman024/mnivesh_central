import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Providers/location_provider.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class LocationRow extends ConsumerWidget {
  const LocationRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final _LocationPillStyle style =
    _LocationPillStyle.forStatus(locationState.status, isDark);

    final Widget content = switch (locationState.status) {
      LocationStatus.checking => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 11.sdp,
            height: 11.sdp,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 1.5,
              backgroundColor: style.iconColor,
            ),
          ),
          SizedBox(width: 6.sdp),
          Text('Fetching location...',
              style: AppTextStyle.light.small(style.textColor)),
        ],
      ),

      LocationStatus.serviceDisabled => _PillTapWrapper(
        onTap: () => Geolocator.openLocationSettings(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warning(), size: 13.sdp, color: style.iconColor),
            SizedBox(width: 6.sdp),
            Text('Location off. Tap to enable.',
                style: AppTextStyle.light.small(style.textColor)),
          ],
        ),
      ),

      LocationStatus.permissionDenied => _PillTapWrapper(
        onTap: () => ref.read(locationProvider.notifier).checkAndFetch(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warning(), size: 13.sdp, color: style.iconColor),
            SizedBox(width: 6.sdp),
            Text('Permission denied. Tap to grant.',
                style: AppTextStyle.light.small(style.textColor)),
          ],
        ),
      ),

      LocationStatus.permissionDeniedForever => _PillTapWrapper(
        onTap: () => Geolocator.openAppSettings(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.prohibit(), size: 13.sdp, color: style.iconColor),
            SizedBox(width: 6.sdp),
            Text('Blocked. Tap to open settings.',
                style: AppTextStyle.light.small(style.textColor)),
          ],
        ),
      ),

      LocationStatus.tooFar => _PillTapWrapper(
        onTap: () => ref.read(locationProvider.notifier).checkAndFetch(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.mapPinArea(), size: 13.sdp, color: style.iconColor),
            SizedBox(width: 6.sdp),
            Text(
              locationState.distanceLabel ?? 'Too far from office',
              style: AppTextStyle.light.small(style.textColor),
            ),
          ],
        ),
      ),

      LocationStatus.ready => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
            size: 13.sdp,
            color: style.iconColor,
          ),
          SizedBox(width: 6.sdp),
          Text(
            locationState.displayName ?? 'Location found',
            style: AppTextStyle.light.small(style.textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    };

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 7.sdp),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: style.borderColor, width: 1),
        ),
        child: content,
      ),
    );
  }
}

// ── Tap wrapper (so the pill itself handles the tap, not GestureDetector leaking outside) ──

class _PillTapWrapper extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PillTapWrapper({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

// ── Pill style model ──────────────────────────────────────────────────────────

class _LocationPillStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _LocationPillStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  factory _LocationPillStyle.forStatus(LocationStatus status, bool isDark) {
    switch (status) {
      case LocationStatus.checking:
        return _LocationPillStyle(
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade100,
          borderColor: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade300,
          iconColor: isDark ? Colors.white38 : Colors.grey.shade400,
          textColor: isDark ? Colors.white38 : Colors.grey.shade500,
        );

      case LocationStatus.serviceDisabled:
      case LocationStatus.permissionDenied:
        return _LocationPillStyle(
          backgroundColor: isDark
              ? Colors.amber.withOpacity(0.12)
              : Colors.amber.shade50,
          borderColor: isDark
              ? Colors.amber.withOpacity(0.25)
              : Colors.amber.shade200,
          iconColor: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
          textColor: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
        );

      case LocationStatus.permissionDeniedForever:
        return _LocationPillStyle(
          backgroundColor: isDark
              ? Colors.red.withOpacity(0.12)
              : Colors.red.shade50,
          borderColor: isDark
              ? Colors.red.withOpacity(0.25)
              : Colors.red.shade200,
          iconColor: isDark ? Colors.red.shade300 : Colors.red.shade600,
          textColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
        );

      case LocationStatus.tooFar:
        return _LocationPillStyle(
          backgroundColor: isDark
              ? Colors.orange.withOpacity(0.12)
              : Colors.orange.shade50,
          borderColor: isDark
              ? Colors.orange.withOpacity(0.25)
              : Colors.orange.shade200,
          iconColor: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
          textColor: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
        );

      case LocationStatus.ready:
        return _LocationPillStyle(
          backgroundColor: isDark
              ? Colors.green.withOpacity(0.12)
              : Colors.green.shade50,
          borderColor: isDark
              ? Colors.green.withOpacity(0.25)
              : Colors.green.shade200,
          iconColor: isDark ? Colors.green.shade300 : Colors.green.shade600,
          textColor: isDark ? Colors.green.shade300 : Colors.green.shade700,
        );
    }
  }
}