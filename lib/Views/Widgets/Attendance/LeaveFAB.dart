import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';

class LeaveFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const LeaveFloatingActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<LeaveFloatingActionButton> createState() => _LeaveFloatingActionButtonState();
}

class _LeaveFloatingActionButtonState extends State<LeaveFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final bgColor = isDark ? colorScheme.surfaceContainerHigh : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.sdp),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        children: [
          // The FAB is static. We don't wrap it in AnimatedBuilder to save CPU/GPU cycles.
          FloatingActionButton.extended(
            onPressed: widget.onPressed,
            backgroundColor: bgColor,
            foregroundColor: colorScheme.primary,
            elevation: 0,
            tooltip: 'Apply Leaves',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sdp),
            ),
            icon: PhosphorIcon(
              PhosphorIcons.listPlus(),
              size: 20.sdp,
              color: colorScheme.primary,
            ),
            label: Text(
              "Leave",
              style: AppTextStyle.normal.custom(14.ssp).copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Position.fill ignores pointer events so the FAB remains clickable.
          // Only this specific painter layer rebuilds on every frame.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RevolvingBorderPainter(
                      progress: _controller.value,
                      baseColor: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                      shineColor: colorScheme.primary.withOpacity(0.3),
                      strokeWidth: 1.5.sdp,
                      radius: 16.sdp,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevolvingBorderPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color shineColor;
  final double strokeWidth;
  final double radius;

  _RevolvingBorderPainter({
    required this.progress,
    required this.baseColor,
    required this.shineColor,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = baseColor;
    canvas.drawRRect(rrect, basePaint);

    // Tightened the gradient stops (0.0 to 0.1) so the shine is just a tiny sliver of light.
    final sweepGradient = SweepGradient(
      colors: [
        Colors.transparent,
        shineColor,
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5],
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = sweepGradient.createShader(rect);

    canvas.drawRRect(rrect, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _RevolvingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.shineColor != shineColor;
  }
}