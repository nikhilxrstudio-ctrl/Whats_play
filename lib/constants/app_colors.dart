import 'package:flutter/material.dart';

class AppColors {
  // Pure Spotify Dark & Black Palette
  static const Color background = Color(0xFF0A0A0A);     // Deep pure black
  static const Color surface = Color(0xFF121212);        // Spotify standard dark surface
  static const Color surfaceLight = Color(0xFF242424);   // Elevated card / chip surface
  static const Color surfaceHighlight = Color(0xFF2A2A2A); // Active / hover surface
  static const Color cardBorder = Color(0xFF1E1E1E);     // Ultra-subtle border
  static const Color bottomBar = Color(0xFF101010);      // Bottom navigation bar color

  // Light & Vibrant Spotify Primary Accent
  static const Color primary = Color(0xFF1ED760);        // Spotify light vibrant neon green
  static const Color primaryLight = Color(0xFF22E56B);   // Bright emerald accent
  static const Color primaryDark = Color(0xFF1AA34A);    // Deep green
  static const Color accent = Color(0xFF1ED760);         // Accent match

  // Status Colors
  static const Color statusSuccess = Color(0xFF1ED760);
  static const Color statusSuccessBg = Color(0xFF0F381D);
  static const Color statusWarning = Color(0xFFFFA500);
  static const Color statusError = Color(0xFFE91429);
  static const Color statusErrorBg = Color(0xFF4A1218);

  // Typography (Spotify Standard)
  static const Color textPrimary = Color(0xFFFFFFFF);    // Crisp white
  static const Color textSecondary = Color(0xFFB3B3B3);  // Muted Spotify gray
  static const Color textMuted = Color(0xFF727272);      // Subtle secondary metadata

  // Audio Status
  static const Color audioFull = Color(0xFF1ED760);
  static const Color audioPreview = Color(0xFFFFA500);
  static const Color audioNone = Color(0xFF727272);
}
