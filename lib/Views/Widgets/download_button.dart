import 'package:flutter/material.dart';

import '../../Themes/AppTextStyle.dart'; // Update path

class DownloadButton extends StatefulWidget {
  final Color activeColor;
  final Color bg;
  final Color fg;
  final int progress;
  final VoidCallback onCancel;

  const DownloadButton({
    super.key,
    required this.activeColor,
    required this.bg,
    required this.fg,
    required this.progress,
    required this.onCancel,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.activeColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
              final targetWidth = maxWidth * (widget.progress / 100).clamp(0, 1);

              return Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeIn,
                    tween: Tween<double>(begin: 0, end: targetWidth.toDouble()),
                    builder: (context, fillWidth, _) {
                      return Stack(
                        children: [
                          Container(width: fillWidth, color: widget.activeColor.withOpacity(0.25)),
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (_, __) {
                              final shimmerX = (maxWidth + 120) * _shimmerController.value - 120;
                              return Positioned(
                                left: shimmerX,
                                child: Opacity(
                                  opacity: shimmerX < fillWidth ? 1.0 : 0.0,
                                  child: Container(
                                    width: 120, height: 50,
                                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [widget.activeColor.withOpacity(0.0), widget.activeColor.withOpacity(0.35), widget.activeColor.withOpacity(0.0)])),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: widget.fg)),
                        const SizedBox(width: 10),
                        Text("Downloading ${widget.progress}%", style: AppTextStyle.bold.normal(widget.fg).copyWith(height: 1.3)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}