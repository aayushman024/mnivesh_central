import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/core/services/custom_haptic_service.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mnivesh_central/features/daftar/providers/location_provider.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/daftar/view_models/attendance_view_model.dart';

/// Represents the various mutually exclusive states of the PunchButton.
enum PunchButtonStatus {
  checkingLocation,
  locationAccessNeeded,
  disabled,
  readyToCheckIn,
  readyToCheckOut,
}

/// Encapsulates the visual configuration for the PunchButton based on its status.
class PunchButtonConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color contentColor;
  final String label;
  final IconData icon;
  final bool isInteractive;
  final bool showShadow;

  const PunchButtonConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.contentColor,
    required this.label,
    required this.icon,
    required this.isInteractive,
    required this.showShadow,
  });

  /// Factory to generate the correct configuration based on current state.
  factory PunchButtonConfig.fromState({
    required PunchButtonStatus status,
    required ThemeData theme,
    required bool isLoading,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final checkOutColor = const Color(0xFFE63946);
    final checkInColor = theme.colorScheme.primary;

    final warningColor =
        isDark ? const Color(0xFFE8A15B) : const Color(0xFFD9822B);
    final warningBgColor =
        isDark ? const Color(0xFF3A2A1B) : const Color(0xFFFFF1E3);
    final warningBorderColor =
        isDark ? const Color(0xFF6A4B2C) : const Color(0xFFF2C9A1);
    final checkOutSolidBg =
        isDark ? const Color(0xFF2E1518) : const Color(0xFFFCEBEC);

    switch (status) {
      case PunchButtonStatus.locationAccessNeeded:
        return PunchButtonConfig(
          backgroundColor: warningBgColor,
          borderColor: warningBorderColor,
          contentColor: warningColor,
          label: 'Location access needed',
          icon: PhosphorIconsRegular.warning,
          isInteractive: false,
          showShadow: false,
        );
      case PunchButtonStatus.disabled:
      case PunchButtonStatus.checkingLocation:
        return PunchButtonConfig(
          backgroundColor: checkInColor.withValues(alpha: 0.38),
          borderColor: Colors.transparent,
          contentColor: Colors.white.withValues(alpha: 0.6),
          label: 'Check In', // Default visual before ready
          icon: PhosphorIconsRegular.handTap,
          isInteractive: false,
          showShadow: false,
        );
      case PunchButtonStatus.readyToCheckIn:
        return PunchButtonConfig(
          backgroundColor: checkInColor,
          borderColor: Colors.transparent,
          contentColor: Colors.white,
          label: 'Check In',
          icon: PhosphorIconsRegular.handTap,
          isInteractive: !isLoading,
          showShadow: true,
        );
      case PunchButtonStatus.readyToCheckOut:
        return PunchButtonConfig(
          backgroundColor: checkOutSolidBg,
          borderColor: checkOutColor,
          contentColor: checkOutColor,
          label: 'Check Out',
          icon: PhosphorIconsRegular.signOut,
          isInteractive: !isLoading,
          showShadow: true,
        );
    }
  }
}

class PunchButton extends ConsumerStatefulWidget {
  final bool isCheckedIn;
  const PunchButton({super.key, required this.isCheckedIn});

  @override
  ConsumerState<PunchButton> createState() => _PunchButtonState();
}

class _PunchButtonState extends ConsumerState<PunchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // snappy scale down effect for tactile feedback
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    CustomHapticService.selection();
    _pressController.forward();
  }

  void _handleTapUp(_) async {
    CustomHapticService.selection();
    setState(() => isLoading = true);
    _pressController.reverse();

    final locationState = ref.read(locationProvider);
    Map<String, dynamic>? locPayload;

    // grab coordinates to pass to the backend
    if (locationState.position != null) {
      locPayload = {
        "type": "Point",
        "coordinates": [
          locationState.position!.longitude,
          locationState.position!.latitude,
        ],
      };
    }

    // await the api call before killing the loading state
    await ref
        .read(attendanceProvider.notifier)
        .togglePunch(location: locPayload);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _handleTapCancel() {
    CustomHapticService.selection();
    _pressController.reverse();
  }

  /// Derives the current status of the punch button based on location and attendance providers.
  PunchButtonStatus _determineStatus(LocationState locationState, bool isOnWFH) {
    final locationReady = locationState.status == LocationStatus.ready;
    final geofenceBypassed =
        isOnWFH && locationState.status == LocationStatus.tooFar;

    if (locationState.status == LocationStatus.checking && !geofenceBypassed) {
      return PunchButtonStatus.checkingLocation;
    }

    final needsLocationAccess = !geofenceBypassed &&
        (locationState.status == LocationStatus.serviceDisabled ||
            locationState.status == LocationStatus.permissionDenied ||
            locationState.status == LocationStatus.permissionDeniedForever);

    if (needsLocationAccess) {
      return PunchButtonStatus.locationAccessNeeded;
    }

    if (locationReady || geofenceBypassed) {
      return widget.isCheckedIn
          ? PunchButtonStatus.readyToCheckOut
          : PunchButtonStatus.readyToCheckIn;
    }

    return PunchButtonStatus.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final isOnWFH = ref.watch(attendanceProvider.select((s) => s.isOnWFH));

    final status = _determineStatus(locationState, isOnWFH);
    final config = PunchButtonConfig.fromState(
      status: status,
      theme: Theme.of(context),
      isLoading: isLoading,
    );

    return GestureDetector(
      onTapDown: config.isInteractive ? _handleTapDown : null,
      onTapUp: config.isInteractive ? _handleTapUp : null,
      onTapCancel: config.isInteractive ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          width: double.infinity,
          height: 54.sdp,
          decoration: _buildDecoration(config),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (status == PunchButtonStatus.checkingLocation)
                _buildShimmerOverlay(),
              _buildMainContent(config, status),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(PunchButtonConfig config) {
    return BoxDecoration(
      color: config.backgroundColor,
      border: Border.all(color: config.borderColor, width: 1.5.sdp),
      borderRadius: BorderRadius.circular(16.sdp),
      boxShadow: config.showShadow
          ? [
              BoxShadow(
                color: widget.isCheckedIn
                    ? Colors.transparent // softer shadow since bg is light
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : [],
    );
  }

  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.sdp),
        child: Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: Colors.white.withValues(alpha: 0.2),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMainContent(PunchButtonConfig config, PunchButtonStatus status) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? _buildLoadingSpinner(config.contentColor)
          : _buildButtonContent(config, status),
    );
  }

  Widget _buildLoadingSpinner(Color color) {
    return SizedBox(
      key: const ValueKey('loading_spinner'),
      width: 24.sdp,
      height: 24.sdp,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildButtonContent(PunchButtonConfig config, PunchButtonStatus status) {
    return Row(
      key: const ValueKey('punch_content'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // icon swap animation: drops in from top
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Icon(
            config.icon,
            key: ValueKey('icon_${status.name}_${widget.isCheckedIn}'),
            size: 24.sdp,
            color: config.contentColor,
          ),
        ),
        SizedBox(width: 8.sdp),
        // animates width difference between check in/out texts
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              config.label,
              key: ValueKey('text_${status.name}_${widget.isCheckedIn}'),
              style: AppTextStyle.bold
                  .normal(config.contentColor),
            ),
          ),
        ),
      ],
    );
  }
}
