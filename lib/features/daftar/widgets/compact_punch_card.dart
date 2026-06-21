import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:mnivesh_central/features/daftar/models/attendance_shift_log.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/daftar/view_models/attendance_view_model.dart';
import 'package:mnivesh_central/features/daftar/widgets/punch_stat.dart';
import 'package:mnivesh_central/features/daftar/widgets/timer_display.dart';

class CompactPunchCard extends ConsumerStatefulWidget {
  const CompactPunchCard({super.key});

  @override
  ConsumerState<CompactPunchCard> createState() => _CompactPunchCardState();
}

class _CompactPunchCardState extends ConsumerState<CompactPunchCard> {
  bool _isExpanded = false;

  List<({DateTime inTime, DateTime? outTime})> _buildSegments(List<PunchEntry> punches) {
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

    if (openIn != null) segments.add((inTime: openIn!, outTime: null));

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final punches = ref.watch(attendanceProvider.select((s) => s.punches));
    final timeIn = ref.watch(attendanceProvider.select((s) => s.firstPunchInTime));
    final timeOut = ref.watch(attendanceProvider.select((s) => s.punchOutTime));
    final segments = _buildSegments(punches);

    return Container(
      width: double.infinity,
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
          Padding(
            padding: EdgeInsets.only(left: 24.sdp, right: 24.sdp, top: 20.sdp, bottom: 16.sdp),
            child: Row(
              children: [
                const CompactTimerDisplayRow(),
                const Spacer(),
                _punchInTile(timeIn != null ? DateFormat('hh:mm a').format(timeIn) : '--:--'),
                const Spacer(),
                _punchOutTile(timeOut != null ? DateFormat('hh:mm a').format(timeOut) : '--:--')
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.sdp),
              decoration: BoxDecoration(
                color: isDark ? Colors.lightBlue.withOpacity(0.15) : Colors.blue.shade50,
                borderRadius: _isExpanded 
                    ? BorderRadius.zero 
                    : BorderRadius.only(
                        bottomLeft: Radius.circular(24.sdp),
                        bottomRight: Radius.circular(24.sdp),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'Hide Punches' : 'View Punches',
                    style: AppTextStyle.bold.custom(13.ssp, theme.colorScheme.primary)
                  ),
                  SizedBox(width: 8.sdp),
                  Icon(
                    _isExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                    color: theme.colorScheme.primary,
                    size: 16.sdp,
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 24.sdp, right: 24.sdp, bottom: 24.sdp, top: 16.sdp),
              child: Column(
                children: [
                  if (segments.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.sdp),
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
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
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
                      outTime,
                      theme.textTheme.bodySmall?.color ?? Colors.grey,
                      isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
            ],
          ),
          SizedBox(height: 14.sdp),
          Row(
            children: [
              Icon(PhosphorIconsRegular.signIn, size: 16.sdp, color: startColor),
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
                isActive ? PhosphorIconsRegular.clock : PhosphorIconsRegular.signOut,
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

Widget _punchInTile(
String punchInTime
    ){
  return Container(
    child: Column(
      children: [
        Icon(PhosphorIconsRegular.arrowDownLeft, color: Colors.green, size: 22.sdp),
        SizedBox(height: 10.sdp),
        Text(punchInTime.isNotEmpty ? punchInTime : "--:--",
        style: AppTextStyle.normal.normal(),)
      ],
    ),
  );
}

Widget _punchOutTile(
String punchOutTime
    ){
  return Column(
    children: [
      Icon(PhosphorIconsRegular.arrowUpRight, color: Colors.red, size: 22.sdp),
      SizedBox(height: 10.sdp),
      Text(punchOutTime.isNotEmpty ? punchOutTime : "--:--",
        style: AppTextStyle.normal.normal(),)
    ],
  );
}
