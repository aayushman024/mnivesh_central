import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';


import '../../../Models/attendance_shiftLog.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/attendance_viewModel.dart';
import 'LocationRow.dart';
import 'PunchButton.dart';
import 'PunchStat.dart';
import 'TimerDisplay.dart';

// ... other imports

class PunchCard extends ConsumerWidget {
  const PunchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCheckedIn =
    ref.watch(attendanceProvider.select((s) => s.isCheckedIn));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.sdp),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24.sdp),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 8.sdp),
          const TimerDisplayRow(),
          SizedBox(height: 32.sdp),

          // Wrap stats in GestureDetector and Hero for the expansion transition
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: const PunchDetailsScreen(),
                    );
                  },
                ),
              );
            },
            child: Hero(
              tag: 'punch_stats_card',
              // Material prevents yellow text artifacts during Hero flight
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 15.sdp),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      PunchInStat(),
                      PunchOutStat(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32.sdp),
          PunchButton(isCheckedIn: isCheckedIn),
          SizedBox(height: 20.sdp),
          const LocationRow(),
        ],
      ),
    );
  }
}

//expanded view
class PunchDetailsScreen extends ConsumerWidget {
  const PunchDetailsScreen({super.key});

  // Pair consecutive in/out punches into segments
  List<({DateTime inTime, DateTime? outTime})> _buildSegments(
      List<PunchEntry> punches) {
    final segments = <({DateTime inTime, DateTime? outTime})>[];
    DateTime? openIn;

    for (final p in punches) {
      if (p.type == 'in') {
        openIn = p.time;
      } else if (p.type == 'out' && openIn != null) {
        segments.add((inTime: openIn!, outTime: p.time));
        openIn = null;
      }
    }

    // Still checked in — open segment
    if (openIn != null) segments.add((inTime: openIn!, outTime: null));

    return segments;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final punches = ref.watch(attendanceProvider.select((s) => s.punches));
    final segments = _buildSegments(punches);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.sdp),
          child: Hero(
            tag: 'punch_stats_card',
            child: Material(
              borderRadius: BorderRadius.circular(24.sdp),
              color: isDark ? theme.colorScheme.surface : Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: double.infinity,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.sdp),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Activity",
                            style: TextStyle(
                              fontSize: 16.sdp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.15),
                            ),
                            child: IconButton(
                              icon: Icon(
                                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                                  size: 20.sdp),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.sdp),
                      if (segments.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.sdp),
                          child: Text(
                            'No activity yet today',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        )
                      else
                        ...segments.map(
                              (seg) => _buildTimelineRow(
                            inTime: DateFormat('hh:mm a').format(seg.inTime),
                            outTime: seg.outTime != null
                                ? DateFormat('hh:mm a').format(seg.outTime!)
                                : null,
                            theme: theme,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow({
    required String inTime,
    required String? outTime,
    required ThemeData theme,
  }) {
    final bool isActive = outTime == null;
    final isDark = theme.brightness == Brightness.dark;
    final startColor = isDark ? Colors.green.shade400 : Colors.green;
    final endColor = isDark ? Colors.redAccent.shade100 : Colors.redAccent;
    final subtleGrey = theme.dividerColor.withOpacity(0.5);

    Widget buildPill(String text, Color textColor, Color bgColor) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 4.sdp),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.sdp),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sdp,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.sdp),
      padding: EdgeInsets.all(12.sdp),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? Colors.white10 : Colors.blueGrey.shade50)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16.sdp),
        border: Border.all(
          color: isActive ? startColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildPill(
                inTime,
                theme.textTheme.bodyMedium?.color ?? Colors.black,
                isDark ? Colors.white10 : Colors.grey.shade100,
              ),
              isActive
                  ? buildPill('Now', startColor, startColor.withOpacity(0.15))
                  : buildPill(
                outTime!,
                theme.textTheme.bodySmall?.color ?? Colors.grey,
                isDark ? Colors.white10 : Colors.grey.shade100,
              ),
            ],
          ),
          SizedBox(height: 14.sdp),
          Row(
            children: [
              Icon(PhosphorIcons.signIn(), size: 16.sdp, color: startColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.sdp),
                  child: SizedBox(
                    height: 2.sdp,
                    child: CustomPaint(
                      painter: DashedLinePainterHorizontal(
                        color: isActive
                            ? startColor.withOpacity(0.7)
                            : subtleGrey,
                        isActive: isActive,
                      ),
                    ),
                  ),
                ),
              ),
              Icon(
                isActive ? PhosphorIcons.clock() : PhosphorIcons.signOut(),
                size: 16.sdp,
                color: isActive ? subtleGrey : endColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashedLinePainterHorizontal extends CustomPainter {
  final Color color;
  final bool isActive;

  DashedLinePainterHorizontal({required this.color, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    var max = size.width;
    var dashWidth = isActive ? 6.0 : 4.0;
    var dashSpace = 4.0;
    double startX = 0;

    while (startX < max) {
      var x2 = startX + dashWidth;
      if (x2 > max) x2 = max;
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(x2, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainterHorizontal oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}