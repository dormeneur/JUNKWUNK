import 'package:flutter/material.dart';

/// Light Green and White Plant-Based Theme Color Palette
/// This color system provides a fresh, clean, and welcoming aesthetic
/// aligned with eco-friendly values.
class AppColors {
  // Light Green Palette - Primary Colors
  static const Color primaryLightest = Color(0xFFE8F5E9); // Lightest green
  static const Color primaryLight = Color(0xFFC8E6C9); // Light green
  static const Color primaryMediumLight = Color(0xFFA5D6A7); // Medium-light green
  static const Color primary = Color(0xFF81C784); // Medium green
  static const Color primaryMedium = Color(0xFF66BB6A); // Medium-strong green
  
  // Legacy aliases for backward compatibility
  static const Color primaryColor = primary; // Medium green
  static const Color secondaryColor = primaryMedium; // Medium-strong green
  static const Color tertiaryColor = primaryMediumLight; // Medium-light green
  static const Color accentColor = primaryLight; // Light green
  static const Color lightAccent = primaryLightest; // Lightest green
  
  // Background Colors
  static const Color white = Color(0xFFFFFFFF); // Pure white
  static const Color backgroundLight = Color(0xFFF1F8F4); // Very light green tint
  static const Color cardBackground = white;
  static const Color scaffoldBackground = backgroundLight;
  static const Color pageBackground = backgroundLight;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2E3B2E); // Dark gray-green
  static const Color textSecondary = Color(0xFF4A7C59); // Medium green
  static const Color textHint = Color(0xFF9E9E9E); // Light gray
  static const Color textLight = Color(0xFF9E9E9E); // Light gray (alias)
  static const Color textDark = Color(0xFF2E3B2E); // Dark gray-green (alias)
  static const Color textOnPrimary = white; // White text on colored backgrounds
  
  // Status Colors
  static const Color success = Color(0xFF66BB6A); // Medium green
  static const Color error = Color(0xFFEF5350); // Soft red
  static const Color warning = Color(0xFFFFA726); // Soft amber
  static const Color info = Color(0xFF4DB6AC); // Blue-green
  
  // Category Colors
  static const Color donate = Color(0xFF81C784); // Medium green
  static const Color recyclable = Color(0xFFA5D6A7); // Medium-light green
  static const Color nonRecyclable = Color(0xFF66BB6A); // Medium-strong green
  static const Color donateColor = donate; // Alias
  static const Color recyclableColor = recyclable; // Alias
  static const Color nonRecyclableColor = nonRecyclable; // Alias
  
  // Border Colors
  static const Color borderLight = Color(0xFFC8E6C9); // Light green border
  static const Color borderMedium = Color(0xFF66BB6A); // Medium green border
  
  // Neutral Colors (for compatibility)
  static const Color grey = Color(0xFF9E9E9E); // Medium grey
  static const Color greyLight = Color(0xFFF5F5F5); // Light grey
  static const Color greyDark = Color(0xFF616161); // Dark grey
  static const Color black = Color(0xFF212121); // Near black
}
