import 'package:flutter/material.dart';

import '../Utils/Dimensions.dart';

class AppTheme {
  AppTheme._();

  // Core Brand Colors
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF60A5FA);
// Change these constants at the top of AppTheme
// NEW neutral grey palette (no blue tint)
  static const Color _darkSlate = Color(0xFF0F1115);   // main background
  static const Color _surfaceDark = Color(0xFF181A20); // cards, neumorphic surface
  static const Color _surfaceElevated = Color(0xFF20232A); // optional elevated
  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: _lightBlue,
      onPrimary: Colors.white,

      secondary: Color(0xFF38BDF8),
      onSecondary: Colors.white,

      surface: _surfaceDark,
      background: _darkSlate,

      error: Color(0xFFFB7185),
    ),

    scaffoldBackgroundColor: _darkSlate,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20.ssp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      color: _surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sdp),
        side: BorderSide(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: BorderSide(
          color: _lightBlue,
          width: 1.5.sdp,
        ),
      ),
    ),
  );

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryBlue,
      onPrimary: Colors.white,
      secondary: Color(0xFF0EA5E9),
      onSecondary: Colors.white,
      surface: Colors.white,
      background: Color(0xFFF8FAFC), // Subtle slate-grey background
      error: Color(0xFFE11D48),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20.ssp,
        fontWeight: FontWeight.w700,
        color: _darkSlate,
      ),
      iconTheme: IconThemeData(color: _darkSlate),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: _darkSlate.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sdp),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal:24.sdp, vertical:14.sdp),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sdp)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.sdp),
        borderSide: BorderSide(color: _primaryBlue, width:1.5.sdp),
      ),
    ),
  );
}