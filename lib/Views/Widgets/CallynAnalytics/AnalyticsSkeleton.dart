import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Utils/Dimensions.dart';

/// Shimmer placeholder shown while analytics data is loading.
class AnalyticsSkeletonLoader extends StatelessWidget {
  const AnalyticsSkeletonLoader({Key? key}) : super(key: key);

  // Pre-computed heights avoid per-call allocation on every build.
  static const List<double> _heights = [160, 180, 180, 180, 180];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor:      cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: ListView.separated(
        padding:         EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 16.sdp),
        physics:         const NeverScrollableScrollPhysics(),
        itemCount:       _heights.length,
        separatorBuilder: (_, __) => SizedBox(height: 16.sdp),
        itemBuilder:     (_, i) => _SkeletonBox(height: _heights[i]),
      ),
    );
  }
}

// ─── _SkeletonBox ─────────────────────────────────────────────────────────────
//
// Extracted as a StatelessWidget (instead of a helper method) so Flutter can
// give each box a stable element node, and the Shimmer gradient travels
// through them as a single layer rather than re-initialising per item.

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     height,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}


/// Displayed inside a card when the data list is empty.
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.sdp),
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize:   13.ssp,
            fontWeight: FontWeight.w400,
            color:      cs.onSurfaceVariant.withOpacity(0.50),
          ),
        ),
      ),
    );
  }
}