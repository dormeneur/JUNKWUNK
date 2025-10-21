import 'package:flutter/material.dart';

/// Design System Constants for JunkWunk App
/// This file contains all UI constants to ensure visual consistency across the app

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF371f97); // Deep purple
  static const Color primaryLight = Color(0xFF5A3EC4);
  static const Color primaryDark = Color(0xFF2A186B);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFEEE8F6); // Light lavender
  static const Color secondaryLight = Color(0xFFF5F5F5);
  
  // Accent Colors
  static const Color accent = Color(0xFF371f97);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Category Colors
  static const Color donate = Color(0xFF4CAF50);
  static const Color recyclable = Color(0xFF2196F3);
  static const Color nonRecyclable = Color(0xFFFF9800);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}

class AppSpacing {
  // Standard spacing units (multiples of 8)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  
  // Common padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  // Horizontal padding
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  
  // Vertical padding
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
}

class AppTypography {
  // Font sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeSM = 12.0;
  static const double fontSizeMD = 14.0;
  static const double fontSizeLG = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSize2XL = 20.0;
  static const double fontSize3XL = 24.0;
  static const double fontSize4XL = 28.0;
  static const double fontSize5XL = 32.0;
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  
  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontSize: fontSize5XL,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: fontSize4XL,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: fontSize3XL,
    fontWeight: bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: fontSize2XL,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSizeLG,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSizeMD,
    fontWeight: regular,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeSM,
    fontWeight: regular,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: fontSizeSM,
    fontWeight: regular,
    color: AppColors.textHint,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: fontSizeLG,
    fontWeight: semiBold,
    color: AppColors.textOnPrimary,
  );
}

class AppBorders {
  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 100.0;
  
  // Border radius objects
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  
  // Border widths
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 2.0;
  static const double borderWidthThick = 3.0;
}

class AppShadows {
  // Elevation shadows
  static List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  // Special shadows
  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class AppButtons {
  // Button heights
  static const double heightSM = 36.0;
  static const double heightMD = 44.0;
  static const double heightLG = 52.0;
  
  // Primary button style
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: AppBorders.borderRadiusMD,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    minimumSize: const Size(0, AppButtons.heightMD),
  );
  
  // Secondary button style
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(
      color: AppColors.primary,
      width: AppBorders.borderWidthMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppBorders.borderRadiusMD,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    minimumSize: const Size(0, AppButtons.heightMD),
  );
  
  // Text button style
  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  );
}

class AppCards {
  // Standard card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    boxShadow: AppShadows.shadowCard,
  );
  
  // Elevated card decoration
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    boxShadow: AppShadows.shadow3,
  );
  
  // Card with border
  static BoxDecoration borderedCardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    border: Border.all(
      color: AppColors.greyLight,
      width: AppBorders.borderWidthThin,
    ),
  );
}

class AppInputs {
  // Input field decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.secondary.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.greyLight,
          width: AppBorders.borderWidthThin,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.greyLight,
          width: AppBorders.borderWidthThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppBorders.borderWidthMedium,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidthThin,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidthMedium,
        ),
      ),
      labelStyle: const TextStyle(color: AppColors.primary),
      hintStyle: const TextStyle(color: AppColors.textHint),
    );
  }
}

class AppAnimations {
  // Standard animation durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Standard curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}
