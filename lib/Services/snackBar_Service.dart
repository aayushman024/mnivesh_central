// lib/Utils/snackbar_service.dart
import 'package:flutter/material.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void _show({
    required String message,
    required IconData icon,
    required Color baseColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey.currentState;
    final context = messenger?.context;
    if (messenger == null || context == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Adaptive background color
    final backgroundColor = isDark ? baseColor.withOpacity(0.90) : baseColor;

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: _AnimatedSnackContent(
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  // 🔴 Error
  static void showError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      message: message,
      icon: Icons.error_rounded,
      baseColor: const Color(0xFFD32F2F),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // 🟢 Success
  static void showSuccess(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      baseColor: const Color(0xFF2E7D32),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showComingSoon({
    String message = 'This feature is coming soon!',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      message: message,
      icon: Icons.watch_later_rounded,
      baseColor: const Color(0xFF1976D2),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _AnimatedSnackContent extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AnimatedSnackContent({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AnimatedSnackContent> createState() => _AnimatedSnackContentState();
}

class _AnimatedSnackContentState extends State<_AnimatedSnackContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: textColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onAction,
                  child: Text(
                    widget.actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
