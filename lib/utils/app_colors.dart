import 'package:flutter/material.dart';

/// App Color Palette - Professional & Production Ready
/// Based on modern design systems (Tailwind, Material Design 3)
class AppColors {
  // Primary Brand Colors
  static const primary = Color(0xFF2563EB); // Blue 600 - Main brand color
  static const primaryLight = Color(0xFF3B82F6); // Blue 500
  static const primaryDark = Color(0xFF1E40AF); // Blue 700

  // Secondary Brand Colors (From ReWatch Logo)
  static const secondary = Color(0xFF1AA3A3); // Teal - Logo accent
  static const secondaryLight = Color(0xFF2DD4BF); // Teal 400
  static const secondaryDark = Color(0xFF0F766E); // Teal 700

  // Neutral Colors
  static const dark = Color(0xFF1E293B); // Slate 800
  static const darkLight = Color(0xFF334155); // Slate 700
  static const gray = Color(0xFF64748B); // Slate 500
  static const grayLight = Color(0xFF94A3B8); // Slate 400
  static const grayBorder = Color(0xFFCBD5E1); // Slate 300
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF); // White

  // Semantic Colors
  static const success = Color(0xFF10B981); // Emerald 500
  static const successLight = Color(0xFF6EE7B7); // Emerald 300
  static const error = Color(0xFFEF4444); // Red 500
  static const errorLight = Color(0xFFFCA5A5); // Red 300
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const warningLight = Color(0xFFFCD34D); // Amber 300
  static const info = Color(0xFF3B82F6); // Blue 500

  // Text Colors
  static const textPrimary = Color(0xFF0F172A); // Slate 900
  static const textSecondary = Color(0xFF475569); // Slate 600
  static const textTertiary = Color(0xFF94A3B8); // Slate 400
  static const textDisabled = Color(0xFFCBD5E1); // Slate 300

  // Special Colors
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Colors.transparent;

  // Gradient
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );
}
