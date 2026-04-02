// lib/Utils/snackbar_service.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum _SnackPosition { top, bottom }

class SnackbarService {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static OverlayEntry? _currentTopEntry;
  static bool _isShowingBottom = false;
  static bool _isShowingTop = false;

  static void _show({
    required String message,
    required PhosphorIconData icon,
    required Color baseColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    _SnackPosition position = _SnackPosition.bottom,
  }) {
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) return;
    final overlay = navigatorState.overlay;
    if (overlay == null) return;
    final theme = Theme.of(navigatorState.context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? baseColor.withOpacity(0.90) : baseColor;

    if (position == _SnackPosition.top) {
      _dismissTop();
    } else {
      _dismissBottom();
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _OverlaySnackbar(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        position: position,
        onDismissed: () {
          if (position == _SnackPosition.top && _currentTopEntry == entry) {
            _dismissTop();
          } else if (position == _SnackPosition.bottom &&
              _currentEntry == entry) {
            _dismissBottom();
          }
        },
      ),
    );

    if (position == _SnackPosition.top) {
      _currentTopEntry = entry;
      _isShowingTop = true;
    } else {
      _currentEntry = entry;
      _isShowingBottom = true;
    }

    overlay.insert(entry);
  }

  static void _dismissBottom() {
    if (_isShowingBottom && _currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
      _isShowingBottom = false;
    }
  }

  static void _dismissTop() {
    if (_isShowingTop && _currentTopEntry != null) {
      try {
        _currentTopEntry?.remove();
      } catch (_) {}
      _currentTopEntry = null;
      _isShowingTop = false;
    }
  }

  // 🔴 Error
  static void showError(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _show(
      message: message,
      icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
      baseColor: const Color(0xFFD32F2F),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // 🟢 Success
  static void showSuccess(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _show(
      message: message,
      icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      baseColor: const Color(0xFF2E7D32),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // 🔵 Coming Soon
  static void showComingSoon(
      {String message = 'This feature is coming soon!',
        String? actionLabel,
        VoidCallback? onAction}) {
    _show(
      message: message,
      icon: PhosphorIcons.hourglassMedium(PhosphorIconsStyle.fill),
      baseColor: const Color(0xFF1976D2),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // 📴 Offline — top, stays until replaced
  static void showOffline(
      {String message = 'No internet. Check your internet connection'}) {
    _show(
      message: message,
      icon: PhosphorIcons.wifiSlash(PhosphorIconsStyle.fill),
      baseColor: const Color(0xFFD32F2F),
      duration: const Duration(days: 365),
      position: _SnackPosition.top,
    );
  }

  // 📶 Online — top
  static void showOnline({String message = 'You are back online'}) {
    _show(
      message: message,
      icon: PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill),
      baseColor: const Color(0xFF2E7D32),
      duration: const Duration(seconds: 3),
      position: _SnackPosition.top,
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------
class _OverlaySnackbar extends StatefulWidget {
  final String message;
  final PhosphorIconData icon;
  final Color backgroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final _SnackPosition position;
  final VoidCallback onDismissed;

  const _OverlaySnackbar({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.duration,
    required this.position,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_OverlaySnackbar> createState() => _OverlaySnackbarState();
}

class _OverlaySnackbarState extends State<_OverlaySnackbar>
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

    // Slide direction based on position
    _slide = Tween<Offset>(
      begin: widget.position == _SnackPosition.top
          ? const Offset(0, -0.25)
          : const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    if (widget.duration < const Duration(hours: 1)) {
      Future.delayed(widget.duration, _animateOut);
    }
  }

  Future<void> _animateOut() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    final isTop = widget.position == _SnackPosition.top;

    return Positioned(
      left: 16,
      right: 16,
      top: isTop ? insets.top + 50 : null,
      bottom: isTop ? null : insets.bottom + 50,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  PhosphorIcon(widget.icon, color: Colors.white, size: 22),
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
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
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
        ),
      ),
    );
  }
}