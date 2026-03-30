import '../../../Models/callyn_analytics_model.dart';
import '../ViewModels/callynAnalytics_viewModel.dart';

// ─── Date-range label helpers ─────────────────────────────────────────────────

/// Returns a human-readable date hint for the given [filter].
String filterDateHint(AnalyticsFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case AnalyticsFilter.today:
      return fmtDate(now);
    case AnalyticsFilter.yesterday:
      return fmtDate(now.subtract(const Duration(days: 1)));
    case AnalyticsFilter.thisWeek:
      final start = now.subtract(Duration(days: now.weekday - 1));
      return '${fmtShort(start)} – ${fmtShort(now)}';
    case AnalyticsFilter.lastWeek:
      final startOfThis = now.subtract(Duration(days: now.weekday - 1));
      final endLast     = startOfThis.subtract(const Duration(days: 1));
      final startLast   = startOfThis.subtract(const Duration(days: 7));
      return '${fmtShort(startLast)} – ${fmtShort(endLast)}';
    case AnalyticsFilter.currentMonth:
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return months[now.month - 1];
    case AnalyticsFilter.allTime:
      return '';
  }
}

/// Full date: `15 Apr 2025`.
String fmtDate(DateTime d) => '${d.day} ${monthAbbr(d.month)} ${d.year}';

/// Short date: `15 Apr`.
String fmtShort(DateTime d) => '${d.day} ${monthAbbr(d.month)}';

/// Returns the 3-letter month abbreviation for month index [m] (1–12).
String monthAbbr(int m) {
  const abbrs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return abbrs[m - 1];
}

// ─── Duration formatting ──────────────────────────────────────────────────────

/// Converts a duration in seconds [s] to a compact human-readable string.
/// e.g. 3780 → `1h 3m`, 125 → `2m 5s`, 45 → `45s`.
String formatDuration(num s) {
  if (s == 0) return '0s';
  final t   = s.round();
  final h   = t ~/ 3600;
  final m   = (t % 3600) ~/ 60;
  final sec = t % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${sec}s';
  return '${sec}s';
}