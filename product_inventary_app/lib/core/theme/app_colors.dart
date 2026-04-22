import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1976D2); // Deep Professional Blue
  static const Color accent = Color(
    0xFF00C853,
  ); // Success Green (Good for Sync/Transfer)

  // Data Source Specific Colors (For UI Cues)
  static const Color restSource = Color(0xFF2196F3); // Blue
  static const Color sqfliteSource = Color(0xFFFF9800); // Orange
  static const Color hiveSource = Color(0xFF9C27B0); // Purple

  // Background & Surface
  static const Color background = Color(0xFFF5F7F9);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  // Text
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
}
