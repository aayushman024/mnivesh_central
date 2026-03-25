// features/attendance/view/widgets/timer_display.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import '../../../ViewModels/attendance_viewModel.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

/// Sole subscriber to [timerProvider]. Rebuilds every second; nothing else does.
class TimerDisplayRow extends ConsumerWidget {
  const TimerDisplayRow({super.key});

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(timerProvider).value ?? Duration.zero;
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;

    final hours   = _pad(duration.inHours);
    final minutes = _pad(duration.inMinutes.remainder(60));
    final seconds = _pad(duration.inSeconds.remainder(60));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimeBox(value: hours,   label: 'hrs',  theme: theme, isDark: isDark),
        _Separator(theme: theme),
        _TimeBox(value: minutes, label: 'mins', theme: theme, isDark: isDark),
        _Separator(theme: theme),
        _TimeBox(value: seconds, label: 'secs', theme: theme, isDark: isDark),
      ],
    );
  }
}

// ── Time box (container + two drum digits) ────────────────────────────────────

class _TimeBox extends StatelessWidget {
  final String value; // always 2-char, e.g. "05"
  final String label;
  final ThemeData theme;
  final bool isDark;

  const _TimeBox({
    required this.value,
    required this.label,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    assert(value.length == 2);
    return Container(
      width: 76.sdp,
      height: 84.sdp,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ClockDrum(digit: value[0], theme: theme),
              SizedBox(width: 1.sdp),
              _ClockDrum(digit: value[1], theme: theme),
            ],
          ),
          SizedBox(height: 4.sdp),
          Text(
            label,
            style: AppTextStyle.normal
                .small(theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Single drum digit — slides old up, new in from below ─────────────────────

// ── Single drum digit — slides old up, new in from below ─────────────────────

class _ClockDrum extends StatelessWidget {
  final String digit;
  final ThemeData theme;

  const _ClockDrum({required this.digit, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.sdp,
      height: 36.sdp,
      child: ClipRect( // Keeps the sliding text contained within the box
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            // Check if the current widget in the builder is the incoming digit
            final isIncoming = (child.key as ValueKey<String>).value == digit;

            // Incoming: starts at Y=1 (below) and moves to Y=0 (center)
            // Outgoing: animation runs 1 -> 0, so tween from (0,-1) to (0,0)
            // makes it start at Y=0 (center) and end at Y=-1 (above)
            final offsetTween = isIncoming
                ? Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                : Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);

            return SlideTransition(
              position: offsetTween.animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut, // smoothed out for a mechanical drum feel
              )),
              child: child, // Dropped FadeTransition to match Cupertino picker style
            );
          },
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [...previous, if (current != null) current],
          ),
          child: Text(
            digit,
            key: ValueKey<String>(digit),
            textAlign: TextAlign.center,
            style: AppTextStyle.extraBold.large(theme.colorScheme.onSurface)
                .copyWith(fontSize: 28.sdp),
          ),
        ),
      ),
    );
  }
}

// ── Colon separator ───────────────────────────────────────────────────────────

class _Separator extends StatelessWidget {
  final ThemeData theme;
  const _Separator({required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 16.sdp, left: 6.sdp, right: 6.sdp),
    child: Text(
      ':',
      style: AppTextStyle.bold
          .large(theme.colorScheme.onSurface.withOpacity(0.3))
          .copyWith(fontSize: 24.sdp),
    ),
  );
}