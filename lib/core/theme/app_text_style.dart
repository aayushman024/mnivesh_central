import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  AppTextStyle._();

  static const _WeightBuilder light = _WeightBuilder(FontWeight.w300);
  static const _WeightBuilder normal = _WeightBuilder(FontWeight.w500);
  static const _WeightBuilder bold = _WeightBuilder(FontWeight.w600);
  static const _WeightBuilder extraBold = _WeightBuilder(FontWeight.w700);
}

class _WeightBuilder {
  final FontWeight weight;

  const _WeightBuilder(this.weight);

  /// Small Text: Size 12
  TextStyle small([Color? color]) {
    return _base(12, color);
  }

  /// Normal Text: Size 16
  TextStyle normal([Color? color]) {
    return _base(16, color);
  }

  /// Large Text: Size 22
  TextStyle large([Color? color]) {
    return _base(22, color);
  }

  /// 🔥 Custom size (same weight)
  TextStyle custom(double size, [Color? color]) {
    return _base(size, color);
  }

  TextStyle _base(double size, Color? color) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}