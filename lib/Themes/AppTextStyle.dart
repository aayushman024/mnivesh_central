import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  // Prevent instantiation
  AppTextStyle._();

  // 1. Static entry points for Weights
  static const _WeightBuilder light = _WeightBuilder(FontWeight.w300);
  static const _WeightBuilder normal = _WeightBuilder(FontWeight.w500);
  static const _WeightBuilder bold = _WeightBuilder(FontWeight.w700);
  static const _WeightBuilder extraBold = _WeightBuilder(FontWeight.w800);
}

// Helper class to handle Sizes and Color
class _WeightBuilder {
  final FontWeight weight;
  const _WeightBuilder(this.weight);

  // 2. Methods for Sizes (accepting optional color override)

  /// Small Text: Size 12
  TextStyle small([Color? color]) {
    return _base(12, color);
  }

  /// Normal Text: Size 16
  TextStyle normal([Color? color]) {
    return _base(16, color);
  }

  /// Large Text: Size 24
  TextStyle large([Color? color]) {
    return _base(22, color);
  }

  // Base Poppins Style
  TextStyle _base(double size, Color? color) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color, // Null color inherits from Theme.of(context).textTheme
    );
  }
}