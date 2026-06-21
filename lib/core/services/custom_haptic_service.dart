import 'dart:io';
import 'package:flutter/services.dart';

class CustomHapticService {
  // standard taps
  static Future<void> light() async => await HapticFeedback.lightImpact();
  static Future<void> medium() async => await HapticFeedback.mediumImpact();
  static Future<void> heavy() async => await HapticFeedback.heavyImpact();

  // native feel for tab selections/pickers
  static Future<void> selection() async {
    if (Platform.isIOS) {
      await HapticFeedback.selectionClick();
    } else {
      await HapticFeedback.lightImpact();
    }
  }
}