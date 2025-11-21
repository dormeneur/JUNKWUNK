# Implementation Plan

- [x] 1. Update Theme System with Light Green Color Palette




  - Update `lib/utils/colors.dart` with new light green color definitions
  - Replace all dark green colors with light green equivalents
  - Add new color constants for backgrounds, text, and accents
  - Ensure semantic naming is maintained (primary, secondary, accent, etc.)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1_

- [ ]* 1.1 Write property test for color palette compliance
  - **Property 1: Color Palette Compliance**
  - **Validates: Requirements 1.2**

- [ ]* 1.2 Write property test for background color restriction
  - **Property 2: Background Color Restriction**
  - **Validates: Requirements 1.3**

- [ ]* 1.3 Write property test for text color consistency
  - **Property 3: Text Color Consistency**
  - **Validates: Requirements 1.4**

- [ ]* 1.4 Write property test for dark green elimination
  - **Property 4: Dark Green Elimination**
  - **Validates: Requirements 1.5**

- [x] 2. Update Design Constants for Light Theme





  - Update `lib/utils/design_constants.dart` with new design system values
  - Update AppColors class with light green palette
  - Update AppShadows class with subtle shadow definitions
  - Update AppButtons class with light green button styles
  - Update AppInputs class with light theme input styles
  - Remove or reduce gradient definitions
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.2, 4.1, 4.2, 4.3, 4.4_

- [ ]* 2.1 Write property test for gradient elimination on cards
  - **Property 5: Gradient Elimination on Cards**
  - **Validates: Requirements 2.1**

- [ ]* 2.2 Write property test for gradient color restriction
  - **Property 6: Gradient Color Restriction**
  - **Validates: Requirements 2.2**

- [ ]* 2.3 Write property test for button solid color requirement
  - **Property 7: Button Solid Color Requirement**
  - **Validates: Requirements 2.3**

- [ ]* 2.4 Write property test for theme system centralization
  - **Property 8: Theme System Centralization**
  - **Validates: Requirements 3.1, 3.2, 3.3**

- [ ]* 2.5 Write property test for card styling consistency
  - **Property 10: Card Styling Consistency**
  - **Validates: Requirements 4.1, 4.3**

- [ ]* 2.6 Write property test for border radius range
  - **Property 11: Border Radius Range**
  - **Validates: Requirements 4.2**

- [ ]* 2.7 Write property test for card border color
  - **Property 12: Card Border Color**
  - **Validates: Requirements 4.4**

- [x] 3. Update AppBar Widget





  - Modify `lib/widgets/app_bar.dart` to use light green background
  - Update background color to #81C784 or #66BB6A
  - Ensure title and icon colors are white
  - Reduce elevation to 2-3dp for subtle shadow
  - Remove any gradient effects
  - _Requirements: 2.5, 6.1, 6.2, 6.5_

- [ ]* 3.1 Write property test for app bar text color
  - **Property 18: App Bar Text Color**
  - **Validates: Requirements 6.2**

- [ ]* 3.2 Write property test for app bar elevation
  - **Property 21: App Bar Elevation**
  - **Validates: Requirements 6.5**
-

- [x] 4. Update Item Card Widget



  - Modify `lib/widgets/item_card.dart` to use white backgrounds
  - Remove gradient effects from card decorations
  - Update shadow to subtle values (2-4px blur, 0.08-0.10 opacity)
  - Update category chip colors to light green shades
  - Update item type chip styling (white background, light green border)
  - Ensure border radius is 12-16px
  - Update button colors to light green with white text
  - _Requirements: 2.1, 4.1, 4.2, 4.3, 4.4, 7.1, 7.5_

- [ ]* 4.1 Write property test for category color differentiation
  - **Property 22: Category Color Differentiation**
  - **Validates: Requirements 7.1**

- [ ]* 4.2 Write property test for item type chip styling
  - **Property 23: Item Type Chip Styling**
  - **Validates: Requirements 7.5**

- [x] 5. Update Button Styles















  - Update primary button styles in design_constants.dart
  - Set primary button background to #66BB6A or #81C784
  - Set primary button text color to white
  - Update secondary button styles (white background, light green border)
  - Add pressed/hover state color variations
  - Update disabled button opacity to 40-50%
  - Remove gradient effects from all buttons
  - _Requirements: 2.3, 5.1, 5.2, 5.3, 5.5_

- [ ]* 5.1 Write property test for primary button styling
  - **Property 13: Primary Button Styling**
  - **Validates: Requirements 5.1**

- [ ]* 5.2 Write property test for secondary button styling
  - **Property 14: Secondary Button Styling**
  - **Validates: Requirements 5.2**

- [ ]* 5.3 Write property test for button interaction states
  - **Property 15: Button Interaction States**
  - **Validates: Requirements 5.3**

- [ ]* 5.4 Write property test for disabled button opacity
  - **Property 17: Disabled Button Opacity**
  - **Validates: Requirements 5.5**
-

- [x] 6. Update Input Field Styles




  - Update input decoration in design_constants.dart
  - Set input background to white
  - Set input border to light green (#C8E6C9)
  - Set focused border to medium green (#66BB6A)
  - Update label color to medium gray or medium green
  - Update placeholder text color to light gray (#9E9E9E)
  - Update input icon color to light green (#81C784)
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ]* 6.1 Write property test for input field styling
  - **Property 25: Input Field Styling**
  - **Validates: Requirements 9.1**

- [ ]* 6.2 Write property test for input focus state
  - **Property 26: Input Focus State**
  - **Validates: Requirements 9.2**

- [ ]* 6.3 Write property test for input label color
  - **Property 27: Input Label Color**
  - **Validates: Requirements 9.3**

- [ ]* 6.4 Write property test for placeholder text color
  - **Property 28: Placeholder Text Color**
  - **Validates: Requirements 9.4**

- [ ]* 6.5 Write property test for input icon color
  - **Property 29: Input Icon Color**
  - **Validates: Requirements 9.5**

- [x] 7. Update Buyer Dashboard Screen





  - Modify `lib/screens/buyer/buyer_dashboard.dart` to use new theme
  - Update scaffold background to white or light green (#F1F8F4)
  - Update tab bar styling (light green background, white indicator)
  - Remove gradient effects
  - Update loading indicator color to light green
  - Ensure all color references use theme system constants
  - _Requirements: 1.1, 1.3, 2.4, 6.3, 8.4_

- [ ]* 7.1 Write property test for tab bar styling
  - **Property 19: Tab Bar Styling**
  - **Validates: Requirements 6.3**

- [ ]* 7.2 Write property test for loading indicator color
  - **Property 24: Loading Indicator Color**
  - **Validates: Requirements 8.4**


- [x] 8. Update Seller Dashboard Screen




  - Modify `lib/screens/seller/seller_dashboard.dart` to use new theme
  - Update scaffold background to white or light green (#F1F8F4)
  - Update section headers with light green accents
  - Update category selection chips to light green shades
  - Update item type selection chips (white background, light green border)
  - Remove gradient effects from all containers
  - Ensure all color references use theme system constants
  - _Requirements: 1.1, 1.3, 2.1, 7.1, 7.5_
-

- [x] 9. Update Buyer Cart Screen




  - Modify `lib/screens/buyer/buyer_cart.dart` to use new theme
  - Update scaffold background to white or light green (#F1F8F4)
  - Update card backgrounds to white with subtle shadows
  - Update category chips to light green shades
  - Update button colors to light green
  - Remove gradient effects
  - Ensure all color references use theme system constants
  - _Requirements: 1.1, 1.3, 2.1, 4.1, 7.1_




- [-] 10. Update Profile Screen

  - Modify `lib/screens/profile/profile_page.dart` to use new theme
  - Update scaffold background to white or light green (#F1F8F4)
  - Update profile cards to white backgrounds with light green accents
  - Update verification badge color to medium green (#66BB6A)
  - Update credit point indicator (light green background, white text)
  - Update info card icons to use light green colors
  - Remove gradient effects from all containers
  - Ensure all color references use theme system constants
  - _Requirements: 1.1, 1.3, 10.2, 10.3, 10.4_

- [ ]* 10.1 Write property test for profile card styling
  - **Property 31: Profile Card Styling**
  - **Validates: Requirements 10.2**

- [x]* 10.2 Write property test for credit point indicator styling




  - **Property 32: Credit Point Indicator Styling**
  - **Validates: Requirements 10.4**

- [ ] 11. Update Login Screen

  - Modify `lib/screens/login_page_cognito.dart` to use new theme
  - Update FlutterLogin theme with light green colors
  - Replace dark green (#132a13) with light green (#81C784)
  - Replace mindaro accent with white or lighter green
  - Update card theme to white background
  - Update button theme to light green
  - Update input theme with light green borders


  - Remove gradient effects
  - _Requirements: 1.1, 10.1_

- [ ]* 11.1 Write property test for login screen color scheme
  - **Property 30: Login Screen Color Scheme**
  - **Validates: Requirements 10.1**

- [ ] 12. Update Dialog and Modal Styles

  - Update logout confirmation dialog in profile_page.dart
  - Change dialog background from dark green to white
  - Update button colors to light green



  - Update icon container colors to light green
  - Update email verification modal styling
  - Ensure all dialogs use white backgrounds with light green accents
  - _Requirements: 10.5_

- [ ]* 12.1 Write property test for dialog styling
  - **Property 33: Dialog Styling**
  - **Validates: Requirements 10.5**

- [ ] 13. Update Status and Feedback Elements

  - Update CustomToast colors in `lib/utils/custom_toast.dart`
  - Set success toast background to medium green (#66BB6A)
  - Set error toast background to soft red (#EF5350)
  - Set warning toast background to soft amber (#FFA726)
  - Update loading indicators throughout the app to light green
  - Ensure all status colors are defined in theme system
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 14. Update Navigation Elements

  - Update bottom navigation bar styling (if present)
  - Set background to white
  - Set active icon color to light green
  - Update any drawer or side menu styling
  - Ensure navigation elements use theme system colors
  - _Requirements: 6.4_

- [ ]* 14.1 Write property test for bottom navigation styling
  - **Property 20: Bottom Navigation Styling**
  - **Validates: Requirements 6.4**






- [ ] 15. Update Icon Button Colors
  - Review all icon buttons across the application
  - Set icon color to light green on white backgrounds


  - Set icon color to white on colored backgrounds
  - Ensure proper contrast ratios
  - Update icon button styles in design_constants.dart
  - _Requirements: 5.4_

- [ ]* 15.1 Write property test for icon color context awareness
  - **Property 16: Icon Color Context Awareness**
  - **Validates: Requirements 5.4**

- [ ] 16. Remove Remaining Gradients





  - Search codebase for LinearGradient and RadialGradient usage
  - Remove or replace gradients with solid colors
  - If gradients are necessary, ensure they use only light green shades
  - Update any background decorations using gradients





  - _Requirements: 2.1, 2.2, 2.4_

- [ ] 17. Verify Theme System Propagation

  - Test that changing a color in theme system updates all screens
  - Verify no hardcoded colors exist outside theme system




  - Ensure all components reference theme constants
  - Run static analysis to find Color() constructors in UI files
  - _Requirements: 3.3, 3.5_

- [ ]* 17.1 Write property test for theme system propagation
  - **Property 9: Theme System Propagation**
  - **Validates: Requirements 3.5**

- [ ] 18. Accessibility Audit

  - Verify all text/background color combinations meet WCAG AA standards
  - Test with screen readers to ensure proper contrast
  - Verify that color is not the only means of conveying information
  - Test with color blindness simulators
  - Document any accessibility issues and fixes
  - _Requirements: 1.4_

- [ ] 19. Visual Regression Testing

  - Capture screenshots of all screens with new theme
  - Compare with original dark green theme screenshots
  - Verify all dark green colors have been replaced
  - Verify gradient removal
  - Document visual changes
  - _Requirements: 1.1, 1.5, 2.1_

- [ ] 20. Final Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.
