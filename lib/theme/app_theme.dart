import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightBgTop = Color(0xFFE8F5E9);
  static const Color lightBgBottom = Color(0xFFB2DFDB);
  static const Color lightGlassBg = Color(0xB3FFFFFF); // 70% white
  static const Color lightGlassBorder = Color(0x4DFFFFFF); // 30% white
  static const Color lightText = Color(0xFF263238);
  
  // Dark Theme Colors
  static const Color darkBgTop = Color(0xFF1C2826);
  static const Color darkBgBottom = Color(0xFF2D403D);
  static const Color darkGlassBg = Color(0x33000000); // 20% black
  static const Color darkGlassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color darkText = Color(0xFFFFFFFF);
  
  // Accent
  static const Color accentColor = Color(0xFFFF9800);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.transparent, // Background handled by container
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      iconTheme: const IconThemeData(color: lightText),
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: const Color(0xFF243431),
      dialogBackgroundColor: const Color(0xFF243431),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF243431),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      iconTheme: const IconThemeData(color: darkText),
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: Color(0xFF243431),
      ),
      useMaterial3: true,
    );
  }
  
  // Helper to build gradient background
  static BoxDecoration gradientBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark 
            ? [darkBgTop, darkBgBottom]
            : [lightBgTop, lightBgBottom],
      ),
    );
  }
}
