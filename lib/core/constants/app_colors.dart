import 'package:flutter/material.dart';

// app-wide color constants
class AppColors {
  AppColors._();

  // primary colors
  static const Color primary = Colors.teal;
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;

  // status card colors
  static final Color statusActiveBackground = Colors.teal.shade50;
  static final Color statusInactiveBackground = Colors.red.shade50;

  // Added for Futuristic / Modern Tone
  static const Color darkBackground = Color(
    0xFF0D1117,
  ); // Deep space dark background
  static const Color glassSurface = Color(
    0x1AFFFFFF,
  ); // Translucent white for glassmorphism
  static const Color glassBorder = Color(
    0x33FFFFFF,
  ); // Subtle light border for glass edges
  static const Color neonCyan = Color(0xFF00F2FE); // Futuristic glowing cyan
}
