import 'package:flutter/material.dart';

/// Design System Constants for JunkWunk App
/// This file contains all UI constants to ensure visual consistency across the app

class AppColors {
  // Light Green Palette - Primary Colors
  static const Color primaryLightest = Color(0xFFE8F5E9); // Lightest green
  static const Color primaryLight = Color(0xFFC8E6C9); // Light green
  static const Color primaryMediumLight = Color(0xFFA5D6A7); // Medium-light green
  static const Color primary = Color(0xFF81C784); // Medium green
  static const Color primaryMedium = Color(0xFF66BB6A); // Medium-strong green
  static const Color primaryDark = Color(0xFF66BB6A); // Medium-strong green (alias)
  
  // Secondary Colors (light green shades)
  static const Color secondary = Color(0xFFC8E6C9); // Light green
  static const Color secondaryLight = Color(0xFFE8F5E9); // Lightest green
  
  // Accent Colors
  static const Color accent = Color(0xFF81C784); // Medium green
  
  // Status Colors
  static const Color success = Color(0xFF66BB6A); // Medium green
  static const Color error = Color(0xFFEF5350); // Soft red
  static const Color warning = Color(0xFFFFA726); // Soft amber
  static const Color info = Color(0xFF4DB6AC); // Blue-green
  
  // Category Colors
  static const Color donate = Color(0xFF81C784); // Medium green
  static const Color recyclable = Color(0xFFA5D6A7); // Medium-light green
  static const Color nonRecyclable = Color(0xFF66BB6A); // Medium-strong green
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF1F8F4); // Very light green tint
  static const Color scaffoldBackground = backgroundLight;
  
  // Border Colors
  static const Color borderLight = Color(0xFFC8E6C9); // Light green border
  static const Color borderMedium = Color(0xFF66BB6A); // Medium green border
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF); // Pure white
  static const Color black = Color(0xFF212121); // Near black
  static const Color grey = Color(0xFF9E9E9E); // Medium grey
  static const Color greyLight = Color(0xFFF5F5F5); // Light grey
  static const Color greyDark = Color(0xFF616161); // Dark grey
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2E3B2E); // Dark gray-green
  static const Color textSecondary = Color(0xFF4A7C59); // Medium green
  static const Color textHint = Color(0xFF9E9E9E); // Light grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on colored backgrounds
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
  // Subtle elevation shadows for light theme
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
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
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Card shadow - subtle for light theme
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> shadowCard = card; // Alias for backward compatibility
  
  // Special shadows
  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}

class AppButtons {
  // Button heights
  static const double heightSM = 36.0;
  static const double heightMD = 44.0;
  static const double heightLG = 52.0;
  
  // Disabled button opacity (40-50%)
  static const double disabledOpacity = 0.45;
  
  // Primary button style - light green with white text
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryMedium, // #66BB6A
    foregroundColor: AppColors.white,
    elevation: 2,
    disabledBackgroundColor: AppColors.primaryMedium.withValues(alpha: disabledOpacity),
    disabledForegroundColor: AppColors.white.withValues(alpha: disabledOpacity),
    shape: RoundedRectangleBorder(
      borderRadius: AppBorders.borderRadiusMD,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    minimumSize: const Size(0, AppButtons.heightMD),
  ).copyWith(
    // Pressed/hover state - darker green
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.white.withValues(alpha: 0.2); // White overlay on press
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.white.withValues(alpha: 0.1); // Subtle white overlay on hover
      }
      return null;
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.primaryMedium.withValues(alpha: disabledOpacity);
      }
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryDark; // Slightly darker on press
      }
      return AppColors.primaryMedium; // Default
    }),
  );
  
  // Alternative primary button with #81C784
  static final ButtonStyle primaryButtonAlt = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary, // #81C784
    foregroundColor: AppColors.white,
    elevation: 2,
    disabledBackgroundColor: AppColors.primary.withValues(alpha: disabledOpacity),
    disabledForegroundColor: AppColors.white.withValues(alpha: disabledOpacity),
    shape: RoundedRectangleBorder(
      borderRadius: AppBorders.borderRadiusMD,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    minimumSize: const Size(0, AppButtons.heightMD),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.white.withValues(alpha: 0.2);
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.white.withValues(alpha: 0.1);
      }
      return null;
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.primary.withValues(alpha: disabledOpacity);
      }
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryMedium; // Slightly darker on press
      }
      return AppColors.primary; // Default
    }),
  );
  
  // Secondary button style - white background with light green border
  static final ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.primaryMedium,
    disabledForegroundColor: AppColors.primaryMedium.withValues(alpha: disabledOpacity),
    side: const BorderSide(
      color: AppColors.borderLight, // Light green border
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
  ).copyWith(
    // Pressed/hover state - light green background
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryLight.withValues(alpha: 0.3); // Light green overlay on press
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primaryLight.withValues(alpha: 0.1); // Subtle overlay on hover
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith<BorderSide?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(
          color: AppColors.borderLight.withValues(alpha: disabledOpacity),
          width: AppBorders.borderWidthMedium,
        );
      }
      if (states.contains(WidgetState.pressed)) {
        return const BorderSide(
          color: AppColors.borderMedium, // Darker border on press
          width: AppBorders.borderWidthMedium,
        );
      }
      return const BorderSide(
        color: AppColors.borderLight,
        width: AppBorders.borderWidthMedium,
      );
    }),
  );
  
  // Text button style - light green text
  static final ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primaryMedium,
    disabledForegroundColor: AppColors.primaryMedium.withValues(alpha: disabledOpacity),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryLight.withValues(alpha: 0.2);
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primaryLight.withValues(alpha: 0.1);
      }
      return null;
    }),
  );
}

class AppCards {
  // Standard card decoration - white with subtle shadow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    boxShadow: AppShadows.card,
  );
  
  // Elevated card decoration - white with slightly more shadow
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    boxShadow: AppShadows.shadow3,
  );
  
  // Card with light green border
  static BoxDecoration borderedCardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppBorders.borderRadiusLG,
    border: Border.all(
      color: AppColors.borderLight, // Light green border
      width: AppBorders.borderWidthThin,
    ),
  );
}

class AppInputs {
  // Input field decoration with light green theme
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
      fillColor: AppColors.white,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.borderLight, // Light green border (#C8E6C9)
          width: AppBorders.borderWidthThin,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.borderLight, // Light green border (#C8E6C9)
          width: AppBorders.borderWidthThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMD,
        borderSide: const BorderSide(
          color: AppColors.borderMedium, // Medium green border on focus (#66BB6A)
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
      labelStyle: const TextStyle(
        color: AppColors.textSecondary, // Medium green (#4A7C59)
        fontSize: AppTypography.fontSizeMD,
        fontWeight: FontWeight.normal,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHint, // Light gray (#9E9E9E)
        fontSize: AppTypography.fontSizeMD,
      ),
      prefixIconColor: AppColors.primary, // Light green (#81C784)
      suffixIconColor: AppColors.primary, // Light green (#81C784)
    );
  }
  
  // Input theme for use in ThemeData
  static InputDecorationTheme inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: AppBorders.borderRadiusMD,
      borderSide: const BorderSide(
        color: AppColors.borderLight, // Light green border (#C8E6C9)
        width: AppBorders.borderWidthThin,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppBorders.borderRadiusMD,
      borderSide: const BorderSide(
        color: AppColors.borderLight, // Light green border (#C8E6C9)
        width: AppBorders.borderWidthThin,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppBorders.borderRadiusMD,
      borderSide: const BorderSide(
        color: AppColors.borderMedium, // Medium green border on focus (#66BB6A)
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
    labelStyle: const TextStyle(
      color: AppColors.textSecondary, // Medium green (#4A7C59)
      fontSize: AppTypography.fontSizeMD,
      fontWeight: FontWeight.normal,
    ),
    hintStyle: const TextStyle(
      color: AppColors.textHint, // Light gray (#9E9E9E)
      fontSize: AppTypography.fontSizeMD,
    ),
    prefixIconColor: AppColors.primary, // Light green (#81C784)
    suffixIconColor: AppColors.primary, // Light green (#81C784)
  );
}

class AppIconButtons {
  // Icon button sizes
  static const double iconSizeSM = 18.0;
  static const double iconSizeMD = 24.0;
  static const double iconSizeLG = 28.0;
  static const double iconSizeXL = 32.0;
  
  // Icon button on white backgrounds - light green icons
  static final ButtonStyle iconButtonOnWhite = IconButton.styleFrom(
    foregroundColor: AppColors.primary, // Light green (#81C784)
    iconSize: iconSizeMD,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryLight.withValues(alpha: 0.3); // Light green overlay on press
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primaryLight.withValues(alpha: 0.1); // Subtle overlay on hover
      }
      return null;
    }),
  );
  
  // Icon button on colored backgrounds - white icons
  static final ButtonStyle iconButtonOnColored = IconButton.styleFrom(
    foregroundColor: AppColors.white, // White icons
    iconSize: iconSizeMD,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.white.withValues(alpha: 0.2); // White overlay on press
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.white.withValues(alpha: 0.1); // Subtle white overlay on hover
      }
      return null;
    }),
  );
  
  // Icon button on light green backgrounds - medium green icons
  static final ButtonStyle iconButtonOnLightGreen = IconButton.styleFrom(
    foregroundColor: AppColors.primaryMedium, // Medium green (#66BB6A)
    iconSize: iconSizeMD,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryMedium.withValues(alpha: 0.2); // Medium green overlay on press
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primaryMedium.withValues(alpha: 0.1); // Subtle overlay on hover
      }
      return null;
    }),
  );
  
  // Helper method to get appropriate icon color based on background
  static Color getIconColor({required Color backgroundColor}) {
    // Calculate relative luminance to determine if background is light or dark
    final luminance = backgroundColor.computeLuminance();
    
    // If background is light (luminance > 0.5), use light green icon
    // If background is dark (luminance <= 0.5), use white icon
    if (luminance > 0.5) {
      return AppColors.primary; // Light green for light backgrounds
    } else {
      return AppColors.white; // White for dark/colored backgrounds
    }
  }
  
  // Helper method to get appropriate icon button style based on background
  static ButtonStyle getIconButtonStyle({required Color backgroundColor}) {
    final luminance = backgroundColor.computeLuminance();
    
    if (luminance > 0.5) {
      return iconButtonOnWhite; // Light green icons for light backgrounds
    } else {
      return iconButtonOnColored; // White icons for dark/colored backgrounds
    }
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
