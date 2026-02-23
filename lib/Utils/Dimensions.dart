import 'dart:math';
import 'package:flutter/widgets.dart';

// We need a singleton to hold the screen size since Dart extensions
// can't implicitly access BuildContext like @Composable does with LocalConfiguration.
class SizeUtil {
  static const double _baseWidth = 425.0;
  static const double _baseHeight = 890.0;

  static double _screenWidth = 0;
  static double _screenHeight = 0;

  // Call this once in the root MaterialApp builder or your base screen
  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _screenHeight = size.height;
  }

  static double get scaleWidth => _screenWidth / _baseWidth;
  static double get scaleHeight => _screenHeight / _baseHeight;
  static double get scaleText => min(scaleWidth, scaleHeight);
}

// Extending num lets us call .sdp and .ssp directly on any int or double
extension ResponsiveNum on num {
  double get sdp => this * SizeUtil.scaleWidth;

  double get ssp => this * SizeUtil.scaleText;
}