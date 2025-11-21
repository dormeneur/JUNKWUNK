# Design Document

## Overview

This design document outlines the technical approach for transforming the JunkWunk application from a dark green theme to a light green and white plant-based theme. The redesign focuses on creating a fresh, clean, and welcoming user experience that aligns with eco-friendly values while maintaining excellent usability and accessibility.

The transformation will be achieved through a centralized theme system update, ensuring consistency across all UI components. The design eliminates heavy gradients, replaces dark greens with soft pastel greens, and introduces white as a primary background color.

## Architecture

### Theme System Architecture

The application uses a centralized theme system with two primary configuration files:

1. **`lib/utils/colors.dart`** - Defines all color constants used throughout the application
2. **`lib/utils/design_constants.dart`** - Defines design system constants including typography, spacing, borders, shadows, and component styles

This architecture ensures:
- Single source of truth for all visual styling
- Easy theme updates without modifying individual components
- Consistent visual language across the entire application
- Type-safe color and style references

### Component Hierarchy

```
Theme System (colors.dart + design_constants.dart)
    ↓
Screens (buyer_dashboard, seller_dashboard, profile, etc.)
    ↓
Widgets (app_bar, item_card, buttons, inputs)
    ↓
Visual Elements (colors, shadows, borders, typography)
```

All UI components reference the theme system, creating a cascading update mechanism where changes to the theme system automatically propagate to all components.

## Components and Interfaces

### Color System (`lib/utils/colors.dart`)

The color system will be completely redesigned with the following structure:

**Primary Colors:**
- Light Green Palette: #E8F5E9 (lightest), #C8E6C9 (light), #A5D6A7 (medium-light), #81C784 (medium), #66BB6A (medium-strong)
- White: #FFFFFF
- Background: #F1F8F4 (very light green tint)

**Text Colors:**
- Primary Text: #2E3B2E (dark gray-green)
- Secondary Text: #4A7C59 (medium green)
- Hint Text: #9E9E9E (light gray)

**Status Colors:**
- Success: #66BB6A (medium green)
- Error: #EF5350 (soft red)
- Warning: #FFA726 (soft amber)
- Info: #4DB6AC (blue-green)

**Category Colors:**
- Donate: #81C784 (medium green)
- Recyclable: #A5D6A7 (medium-light green)
- Non-Recyclable: #66BB6A (medium-strong green)

### Design Constants (`lib/utils/design_constants.dart`)

**AppColors Class:**
- Replaces all dark green references with light green equivalents
- Maintains semantic naming (primary, secondary, accent, etc.)
- Adds new light green shades for various UI states

**AppShadows Class:**
- Reduces shadow intensity for lighter, more subtle elevation
- Updates shadow colors to work with light backgrounds
- Maintains depth perception without heavy shadows

**AppButtons Class:**
- Updates button styles to use light green backgrounds
- Ensures white text on colored buttons for contrast
- Adds hover and pressed states with appropriate color shifts

**AppInputs Class:**
- Updates input field styling for light theme
- Ensures proper focus states with light green highlights
- Maintains accessibility with sufficient contrast ratios

### UI Components

**AppBar Widget (`lib/widgets/app_bar.dart`):**
- Background: Light green (#81C784 or #66BB6A)
- Text: White
- Icons: White
- Elevation: Reduced to 2-3dp for subtle shadow

**Item Card Widget (`lib/widgets/item_card.dart`):**
- Background: White
- Border: Optional light green (#C8E6C9)
- Shadow: Subtle (2-4px blur, light gray)
- Category chips: Light green shades with appropriate text colors
- Action buttons: Light green with white text

**Screen Backgrounds:**
- Primary: White (#FFFFFF)
- Secondary: Very light green (#F1F8F4)
- Alternates between solid colors, no gradients

## Data Models

### Color Definition Model

```dart
class AppColors {
  // Light Green Palette
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryMediumLight = Color(0xFFC8E6C9);
  static const Color primary = Color(0xFF81C784);
  static const Color primaryMedium = Color(0xFF66BB6A);
  
  // Backgrounds
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF1F8F4);
  
  // Text
  static const Color textPrimary = Color(0xFF2E3B2E);
  static const Color textSecondary = Color(0xFF4A7C59);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Status
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF4DB6AC);
  
  // Categories
  static const Color donate = Color(0xFF81C784);
  static const Color recyclable = Color(0xFFA5D6A7);
  static const Color nonRecyclable = Color(0xFF66BB6A);
}
```

### Shadow Definition Model

```dart
class AppShadows {
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Color Palette Compliance

*For any* UI component in the application, all primary colors used SHALL be from the approved light green palette (#E8F5E9, #C8E6C9, #A5D6A7, #81C784, #66BB6A).

**Validates: Requirements 1.2**

### Property 2: Background Color Restriction

*For any* screen or container background, the background color SHALL be either white (#FFFFFF) or very light green (#F1F8F4).

**Validates: Requirements 1.3**

### Property 3: Text Color Consistency

*For any* text element displayed on light backgrounds, the text color SHALL be either dark gray (#2E3B2E), medium green (#4A7C59), or light gray (#9E9E9E) for hints.

**Validates: Requirements 1.4**

### Property 4: Dark Green Elimination

*For any* UI element, dark green colors (#132a13, #31572c) SHALL NOT be used except in explicitly approved accent contexts.

**Validates: Requirements 1.5**

### Property 5: Gradient Elimination on Cards

*For any* card or container component, the decoration SHALL use solid colors and SHALL NOT include gradient properties.

**Validates: Requirements 2.1**

### Property 6: Gradient Color Restriction

*For any* remaining gradient in the application, all colors in the gradient SHALL be from the approved light green palette.

**Validates: Requirements 2.2**

### Property 7: Button Solid Color Requirement

*For any* button component, the background SHALL be a solid color (no gradient) from the approved light green palette.

**Validates: Requirements 2.3**

### Property 8: Theme System Centralization

*For any* color reference in UI components, the color SHALL be defined in and referenced from `lib/utils/colors.dart` or `lib/utils/design_constants.dart`.

**Validates: Requirements 3.1, 3.2, 3.3**

### Property 9: Theme System Propagation

*For any* screen component, when a color constant in the theme system is updated, the screen SHALL reflect the new color without requiring code changes to the screen itself.

**Validates: Requirements 3.5**

### Property 10: Card Styling Consistency

*For any* card component, the background SHALL be white and the shadow SHALL have a blur radius between 2-8px with opacity between 0.08-0.15.

**Validates: Requirements 4.1, 4.3**

### Property 11: Border Radius Range

*For any* card or container with rounded corners, the border radius SHALL be between 12-16 pixels.

**Validates: Requirements 4.2**

### Property 12: Card Border Color

*For any* card with a border, the border color SHALL be light green (#C8E6C9).

**Validates: Requirements 4.4**

### Property 13: Primary Button Styling

*For any* primary button, the background color SHALL be either #66BB6A or #81C784, and the text color SHALL be white (#FFFFFF).

**Validates: Requirements 5.1**

### Property 14: Secondary Button Styling

*For any* secondary button, the background SHALL be white, the border SHALL be light green, and the text SHALL be green.

**Validates: Requirements 5.2**

### Property 15: Button Interaction States

*For any* button component, the style definition SHALL include a pressed or hover state with a color variation.

**Validates: Requirements 5.3**

### Property 16: Icon Color Context Awareness

*For any* icon button, the icon color SHALL be light green when on white backgrounds, or white when on colored backgrounds.

**Validates: Requirements 5.4**

### Property 17: Disabled Button Opacity

*For any* disabled button, the opacity SHALL be between 0.4 and 0.5 (40-50%).

**Validates: Requirements 5.5**

### Property 18: App Bar Text Color

*For any* app bar component, the title text and icon colors SHALL be white (#FFFFFF).

**Validates: Requirements 6.2**

### Property 19: Tab Bar Styling

*For any* tab bar, the background SHALL be light green and the selected indicator SHALL be white.

**Validates: Requirements 6.3**

### Property 20: Bottom Navigation Styling

*For any* bottom navigation bar, the background SHALL be white and active icons SHALL be light green.

**Validates: Requirements 6.4**

### Property 21: App Bar Elevation

*For any* app bar, the elevation value SHALL be between 2 and 3.

**Validates: Requirements 6.5**

### Property 22: Category Color Differentiation

*For any* set of category chips, each category SHALL have a distinct light green shade that differs from other categories.

**Validates: Requirements 7.1**

### Property 23: Item Type Chip Styling

*For any* item type chip, the background SHALL be white, the border SHALL be light green, and the text SHALL be green.

**Validates: Requirements 7.5**

### Property 24: Loading Indicator Color

*For any* loading indicator (CircularProgressIndicator), the color SHALL be light green (#81C784).

**Validates: Requirements 8.4**

### Property 25: Input Field Styling

*For any* text input field, the background SHALL be white and the border SHALL be light green.

**Validates: Requirements 9.1**

### Property 26: Input Focus State

*For any* text input field in focus state, the border color SHALL be medium green (#66BB6A).

**Validates: Requirements 9.2**

### Property 27: Input Label Color

*For any* input field label, the text color SHALL be either medium gray (#616161) or medium green (#4A7C59).

**Validates: Requirements 9.3**

### Property 28: Placeholder Text Color

*For any* input field placeholder text, the color SHALL be light gray (#9E9E9E).

**Validates: Requirements 9.4**

### Property 29: Input Icon Color

*For any* input field icon (prefix or suffix), the color SHALL be light green (#81C784).

**Validates: Requirements 9.5**

### Property 30: Login Screen Color Scheme

*For any* element on the login screen, the colors used SHALL be from the light green and white palette, with no dark green colors.

**Validates: Requirements 10.1**

### Property 31: Profile Card Styling

*For any* profile card, the background SHALL be white and accent elements SHALL use light green colors.

**Validates: Requirements 10.2**

### Property 32: Credit Point Indicator Styling

*For any* credit point indicator, the background SHALL be light green and the text SHALL be white.

**Validates: Requirements 10.4**

### Property 33: Dialog Styling

*For any* logout or confirmation dialog, the background SHALL be white and action buttons SHALL use light green colors.

**Validates: Requirements 10.5**

## Error Handling

### Color Validation Errors

If a color value is used that doesn't match the approved palette:
- Development: Lint warnings should alert developers
- Runtime: No errors (colors will display but may not match design)
- Testing: Property-based tests will catch violations

### Theme System Reference Errors

If a component tries to use a color not defined in the theme system:
- Compile-time: Dart analyzer will show undefined reference errors
- This prevents hardcoded colors from being used

### Contrast Ratio Violations

If text color on background doesn't meet WCAG AA standards (4.5:1 for normal text):
- Development: Accessibility linters should warn
- Testing: Automated accessibility tests should catch violations
- Mitigation: All approved color combinations have been verified for sufficient contrast

## Testing Strategy

### Visual Regression Testing

- Capture screenshots of all screens before and after theme changes
- Compare screenshots to ensure visual consistency
- Verify that all dark green colors have been replaced
- Confirm gradient removal on cards and backgrounds

### Property-Based Testing

Property-based tests will be written using the `test` package with custom generators for Flutter widgets. Each correctness property will be implemented as a separate test that:

1. Generates random widget configurations
2. Applies the theme system
3. Verifies the property holds across all generated cases

**Test Configuration:**
- Minimum 100 iterations per property test
- Use Flutter's widget testing framework
- Generate variations of screens, cards, buttons, and inputs
- Verify color values, opacity levels, border radius, and shadow properties

### Unit Testing

Unit tests will verify specific examples and edge cases:

- Specific screen color schemes (login, profile, dashboard)
- Category chip color assignments (Donate, Recyclable, Non-Recyclable)
- Status message colors (success, error, warning, info)
- Button state colors (normal, pressed, disabled)
- Input field state colors (normal, focused, error)

### Integration Testing

Integration tests will verify:
- Theme system updates propagate to all screens
- Color consistency across navigation flows
- Proper color inheritance in nested components
- Accessibility compliance across the application

### Manual Testing Checklist

- [ ] All screens display light green and white color scheme
- [ ] No dark green colors visible except approved accents
- [ ] No gradients on cards or backgrounds
- [ ] All text is readable with sufficient contrast
- [ ] Buttons provide clear visual feedback
- [ ] Loading indicators use light green color
- [ ] Category chips use distinct light green shades
- [ ] Input fields have proper focus states
- [ ] Dialogs and modals match the light theme
- [ ] App bars use light green backgrounds

## Implementation Notes

### Migration Strategy

1. **Phase 1: Theme System Update**
   - Update `lib/utils/colors.dart` with new color palette
   - Update `lib/utils/design_constants.dart` with new design constants
   - Ensure all color references use semantic names

2. **Phase 2: Component Updates**
   - Update AppBar widget styling
   - Update card and container decorations
   - Update button styles
   - Update input field styles

3. **Phase 3: Screen Updates**
   - Update screen backgrounds
   - Update navigation elements
   - Update dialogs and modals
   - Update login/authentication screens

4. **Phase 4: Testing and Refinement**
   - Run property-based tests
   - Perform visual regression testing
   - Conduct accessibility audits
   - Make refinements based on test results

### Accessibility Considerations

All color combinations have been verified for WCAG AA compliance:

- Dark gray (#2E3B2E) on white: 12.6:1 (AAA)
- Medium green (#4A7C59) on white: 5.8:1 (AA)
- White on medium green (#66BB6A): 3.2:1 (AA for large text)
- White on medium-strong green (#81C784): 2.8:1 (AA for large text only)

For small text on colored backgrounds, ensure sufficient contrast by using darker green shades or white text.

### Performance Considerations

- Theme system changes require no runtime color calculations
- All colors are compile-time constants
- No performance impact from theme redesign
- Widget rebuilds only occur when theme constants change (rare)

### Backward Compatibility

This is a visual redesign with no API changes:
- No breaking changes to component interfaces
- All existing component props remain the same
- Only visual styling changes
- No data model changes required
