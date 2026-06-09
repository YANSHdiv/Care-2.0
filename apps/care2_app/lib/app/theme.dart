/// Care 2.0 — Clinical Dark Theme
/// Premium health-tech design system with glassmorphism and micro-animations.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Care2Theme {
  Care2Theme._();

  // ─── Brand Colors ───
  static const Color primary = Color(0xFF00E5A0);        // Emerald Green
  static const Color primaryDark = Color(0xFF00B87A);
  static const Color secondary = Color(0xFF7C4DFF);       // Deep Purple
  static const Color secondaryLight = Color(0xFF9E7DFF);
  static const Color accent = Color(0xFF00D4FF);           // Cyan accent
  
  // ─── Surface Colors ───
  static const Color surface = Color(0xFF1A1A2E);         // Deep navy base
  static const Color surfaceVariant = Color(0xFF16213E);  // Slightly lighter
  static const Color cardColor = Color(0xFF0F3460);       // Blue-tinted card
  static const Color cardColorLight = Color(0xFF1A4080);
  static const Color scaffoldBg = Color(0xFF0D1117);      // Near-black bg
  
  // ─── Risk Colors ───
  static const Color riskGreen = Color(0xFF00E676);
  static const Color riskAmber = Color(0xFFFFD600);
  static const Color riskRed = Color(0xFFFF1744);
  static const Color riskGreenBg = Color(0x2000E676);
  static const Color riskAmberBg = Color(0x20FFD600);
  static const Color riskRedBg = Color(0x20FF1744);
  
  // ─── Text Colors ───
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF78909C);
  
  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F3460), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ─── Glassmorphism ───
  static BoxDecoration glassDecoration({
    double opacity = 0.1,
    double borderRadius = 20,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.15),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ],
    );
  }
  
  static BoxDecoration glowDecoration({
    required Color color,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 50,
          spreadRadius: -10,
        ),
      ],
    );
  }
  
  // ─── Theme Data ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Color(0xFF003300),
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textTertiary, fontSize: 12),
          labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF003300),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: riskRed),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceVariant,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(color: Color(0xFF003300), fontWeight: FontWeight.w600),
      ),
    );
  }
}
