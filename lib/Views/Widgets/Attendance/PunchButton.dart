// ── Punch button ──────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Services/CustomHapticService.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Providers/location_provider.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/attendance_viewModel.dart';

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

  void _handleTapUp(_) {
    CustomHapticService.selection();
    _pressController.reverse();
    ref.read(attendanceProvider.notifier).togglePunch();
  }

  void _handleTapCancel() {
    CustomHapticService.selection();
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // disable interactions until location is fetched
    final locationReady = ref.watch(
      locationProvider.select((s) => s.status == LocationStatus.ready),
    );

    // red for checkout, theme primary for checkin
    final activeColor = widget.isCheckedIn
        ? const Color(0xFFE63946)
        : theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: locationReady ? _handleTapDown : null,
      onTapUp: locationReady ? _handleTapUp : null,
      onTapCancel: locationReady ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          width: double.infinity,
          height: 54.sdp,
          decoration: BoxDecoration(
            color: locationReady
                ? activeColor
                : theme.colorScheme.primary.withOpacity(0.38),
            borderRadius: BorderRadius.circular(16.sdp),
            boxShadow: locationReady
                ? [
              BoxShadow(
                color: activeColor.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // loading state shimmer overlay
              if (!locationReady)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.sdp),
                    child: Shimmer.fromColors(
                      baseColor: Colors.transparent,
                      highlightColor: Colors.white.withOpacity(0.2),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),

              Row(
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
                      widget.isCheckedIn
                          ? PhosphorIcons.signOut()
                          : PhosphorIcons.handTap(),
                      key: ValueKey('icon_${widget.isCheckedIn}'),
                      size: 24.sdp,
                      color: locationReady
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: 8.sdp),

                  // smoothly animates the width difference between check in/out texts
                  // to prevent the icon from snapping sideways
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
                        widget.isCheckedIn ? 'Check Out' : 'Check In',
                        key: ValueKey('text_${widget.isCheckedIn}'),
                        style: AppTextStyle.bold
                            .normal(locationReady
                            ? Colors.white
                            : Colors.white.withOpacity(0.6))
                            .copyWith(inherit: false),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}