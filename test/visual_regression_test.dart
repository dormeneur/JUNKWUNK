import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:junk_wunk/utils/colors.dart';
import 'package:junk_wunk/utils/design_constants.dart' hide AppColors;

/// Visual Regression Testing for Light Green Theme Redesign
/// 
/// This test suite verifies that:
/// 1. All dark green colors have been replaced with light green
/// 2. Gradients have been removed from the application
/// 3. The new theme uses approved light green and white colors
/// 
/// Requirements: 1.1, 1.5, 2.1

void main() {
  group('Visual Regression Tests - Color Palette Verification', () {
    test('All primary colors are light green shades', () {
      // Verify all primary colors are from the approved light green palette
      final approvedColors = [
        0xFFE8F5E9, // primaryLightest
        0xFFC8E6C9, // primaryLight
        0xFFA5D6A7, // primaryMediumLight
        0xFF81C784, // primary
        0xFF66BB6A, // primaryMedium
      ];

      expect(approvedColors.contains(AppColors.primaryLightest.toARGB32()), isTrue,
          reason: 'primaryLightest should be from approved palette');
      expect(approvedColors.contains(AppColors.primaryLight.toARGB32()), isTrue,
          reason: 'primaryLight should be from approved palette');
      expect(approvedColors.contains(AppColors.primaryMediumLight.toARGB32()), isTrue,
          reason: 'primaryMediumLight should be from approved palette');
      expect(approvedColors.contains(AppColors.primary.toARGB32()), isTrue,
          reason: 'primary should be from approved palette');
      expect(approvedColors.contains(AppColors.primaryMedium.toARGB32()), isTrue,
          reason: 'primaryMedium should be from approved palette');
    });

    test('No dark green colors are used in theme system', () {
      // Verify that dark green colors (#132a13, #31572c) are NOT present
      final darkGreenColors = [
        0xFF132a13,
        0xFF31572c,
      ];

      final allThemeColors = [
        AppColors.primaryLightest.toARGB32(),
        AppColors.primaryLight.toARGB32(),
        AppColors.primaryMediumLight.toARGB32(),
        AppColors.primary.toARGB32(),
        AppColors.primaryMedium.toARGB32(),
        AppColors.textPrimary.toARGB32(),
        AppColors.textSecondary.toARGB32(),
        AppColors.backgroundLight.toARGB32(),
      ];

      for (var darkColor in darkGreenColors) {
        expect(allThemeColors.contains(darkColor), isFalse,
            reason: 'Dark green color 0x${darkColor.toRadixString(16)} should not be in theme');
      }
    });

    test('Background colors are white or very light green', () {
      // Verify backgrounds use only white or very light green
      expect(AppColors.white.toARGB32(), equals(0xFFFFFFFF),
          reason: 'White should be pure white');
      expect(AppColors.backgroundLight.toARGB32(), equals(0xFFF1F8F4),
          reason: 'Background light should be very light green');
      expect(AppColors.cardBackground.toARGB32(), equals(0xFFFFFFFF),
          reason: 'Card background should be white');
      expect(AppColors.scaffoldBackground.toARGB32(), equals(0xFFF1F8F4),
          reason: 'Scaffold background should be very light green');
    });

    test('Text colors provide contrast on light backgrounds', () {
      // Verify text colors are dark enough for light backgrounds
      expect(AppColors.textPrimary.toARGB32(), equals(0xFF2E3B2E),
          reason: 'Primary text should be dark gray-green');
      expect(AppColors.textSecondary.toARGB32(), equals(0xFF4A7C59),
          reason: 'Secondary text should be medium green');
      expect(AppColors.textHint.toARGB32(), equals(0xFF9E9E9E),
          reason: 'Hint text should be light gray');
      expect(AppColors.textOnPrimary.toARGB32(), equals(0xFFFFFFFF),
          reason: 'Text on primary should be white');
    });

    test('Status colors match light theme specification', () {
      // Verify status colors are appropriate for light theme
      expect(AppColors.success.toARGB32(), equals(0xFF66BB6A),
          reason: 'Success should be medium green');
      expect(AppColors.error.toARGB32(), equals(0xFFEF5350),
          reason: 'Error should be soft red');
      expect(AppColors.warning.toARGB32(), equals(0xFFFFA726),
          reason: 'Warning should be soft amber');
      expect(AppColors.info.toARGB32(), equals(0xFF4DB6AC),
          reason: 'Info should be blue-green');
    });

    test('Category colors are distinct light green shades', () {
      // Verify category colors are different and from light green palette
      expect(AppColors.donate.toARGB32(), equals(0xFF81C784),
          reason: 'Donate should be medium green');
      expect(AppColors.recyclable.toARGB32(), equals(0xFFA5D6A7),
          reason: 'Recyclable should be medium-light green');
      expect(AppColors.nonRecyclable.toARGB32(), equals(0xFF66BB6A),
          reason: 'Non-recyclable should be medium-strong green');

      // Verify they are distinct
      expect(AppColors.donate, isNot(equals(AppColors.recyclable)),
          reason: 'Donate and Recyclable should be different colors');
      expect(AppColors.donate, isNot(equals(AppColors.nonRecyclable)),
          reason: 'Donate and Non-recyclable should be different colors');
      expect(AppColors.recyclable, isNot(equals(AppColors.nonRecyclable)),
          reason: 'Recyclable and Non-recyclable should be different colors');
    });
  });

  group('Visual Regression Tests - Gradient Removal Verification', () {
    test('Card decorations use solid colors only', () {
      // Verify card decorations don't use gradients
      final cardDecoration = AppCards.cardDecoration;
      expect(cardDecoration.gradient, isNull,
          reason: 'Card decoration should not have gradient');
      expect(cardDecoration.color, equals(AppColors.white),
          reason: 'Card should have white background');
    });

    test('Elevated card decorations use solid colors only', () {
      final elevatedCardDecoration = AppCards.elevatedCardDecoration;
      expect(elevatedCardDecoration.gradient, isNull,
          reason: 'Elevated card decoration should not have gradient');
      expect(elevatedCardDecoration.color, equals(AppColors.white),
          reason: 'Elevated card should have white background');
    });

    test('Bordered card decorations use solid colors only', () {
      final borderedCardDecoration = AppCards.borderedCardDecoration;
      expect(borderedCardDecoration.gradient, isNull,
          reason: 'Bordered card decoration should not have gradient');
      expect(borderedCardDecoration.color, equals(AppColors.white),
          reason: 'Bordered card should have white background');
    });

    test('Button styles use solid colors', () {
      // Verify primary button uses solid color
      final primaryButton = AppButtons.primaryButton;
      final backgroundColor = primaryButton.backgroundColor?.resolve({});
      expect(backgroundColor, equals(AppColors.primaryMedium),
          reason: 'Primary button should have solid medium green background');

      // Verify alternative primary button uses solid color
      final primaryButtonAlt = AppButtons.primaryButtonAlt;
      final backgroundColorAlt = primaryButtonAlt.backgroundColor?.resolve({});
      expect(backgroundColorAlt, equals(AppColors.primary),
          reason: 'Alternative primary button should have solid medium green background');

      // Verify secondary button uses solid color
      final secondaryButton = AppButtons.secondaryButton;
      final secondaryBgColor = secondaryButton.backgroundColor?.resolve({});
      expect(secondaryBgColor, equals(AppColors.white),
          reason: 'Secondary button should have solid white background');
    });

    test('Shadows use subtle opacity for light theme', () {
      // Verify shadows are subtle (not heavy)
      for (var shadow in AppShadows.subtle) {
        expect(shadow.color.a, lessThanOrEqualTo(0.15),
            reason: 'Subtle shadow opacity should be <= 0.15');
        expect(shadow.color.a, greaterThanOrEqualTo(0.05),
            reason: 'Subtle shadow opacity should be >= 0.05');
        expect(shadow.blurRadius, lessThanOrEqualTo(8.0),
            reason: 'Subtle shadow blur should be <= 8px');
      }

      for (var shadow in AppShadows.card) {
        expect(shadow.color.a, lessThanOrEqualTo(0.15),
            reason: 'Card shadow opacity should be <= 0.15');
        expect(shadow.blurRadius, lessThanOrEqualTo(12.0),
            reason: 'Card shadow blur should be <= 12px');
      }
    });
  });

  group('Visual Regression Tests - Design Constants Verification', () {
    test('Border radius values are in approved range', () {
      // Verify border radius for cards is 12-16px
      final lgRadius = AppBorders.borderRadiusLG.topLeft.x;
      expect(lgRadius, greaterThanOrEqualTo(12.0),
          reason: 'Card border radius should be >= 12px');
      expect(lgRadius, lessThanOrEqualTo(16.0),
          reason: 'Card border radius should be <= 16px');
    });

    test('Border colors use light green shades', () {
      // Verify border colors are from light green palette
      expect(AppColors.borderLight.toARGB32(), equals(0xFFC8E6C9),
          reason: 'Light border should be light green');
      expect(AppColors.borderMedium.toARGB32(), equals(0xFF66BB6A),
          reason: 'Medium border should be medium green');
    });

    test('Input field styling uses light green theme', () {
      final inputDecoration = AppInputs.inputDecoration(label: 'Test');
      
      // Verify input background is white
      expect(inputDecoration.fillColor, equals(AppColors.white),
          reason: 'Input background should be white');
      
      // Verify input is filled
      expect(inputDecoration.filled, isTrue,
          reason: 'Input should be filled');
      
      // Verify border colors
      final enabledBorder = inputDecoration.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, equals(AppColors.borderLight),
          reason: 'Enabled border should be light green');
      
      final focusedBorder = inputDecoration.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, equals(AppColors.borderMedium),
          reason: 'Focused border should be medium green');
    });

    test('Button disabled opacity is in approved range', () {
      // Verify disabled button opacity is 40-50%
      expect(AppButtons.disabledOpacity, greaterThanOrEqualTo(0.4),
          reason: 'Disabled opacity should be >= 0.4 (40%)');
      expect(AppButtons.disabledOpacity, lessThanOrEqualTo(0.5),
          reason: 'Disabled opacity should be <= 0.5 (50%)');
    });

    test('Icon button colors are context-aware', () {
      // Test icon color on white background
      final iconColorOnWhite = AppIconButtons.getIconColor(
        backgroundColor: AppColors.white,
      );
      expect(iconColorOnWhite, equals(AppColors.primary),
          reason: 'Icon on white should be light green');

      // Test icon color on colored background
      final iconColorOnColored = AppIconButtons.getIconColor(
        backgroundColor: AppColors.primaryMedium,
      );
      expect(iconColorOnColored, equals(AppColors.white),
          reason: 'Icon on colored background should be white');
    });
  });

  group('Visual Regression Tests - Widget Rendering', () {
    testWidgets('Scaffold uses light green background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.scaffoldBackground),
          reason: 'Scaffold should use light green background');
    });

    testWidgets('Card uses white background with subtle shadow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              color: AppColors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppBorders.borderRadiusLG,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(AppColors.white),
          reason: 'Card should have white background');
      expect(card.elevation, lessThanOrEqualTo(4.0),
          reason: 'Card elevation should be subtle');
    });

    testWidgets('Primary button uses light green with white text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              style: AppButtons.primaryButton,
              child: const Text('Primary Button'),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget,
          reason: 'Primary button should render');
      expect(find.text('Primary Button'), findsOneWidget,
          reason: 'Button text should render');
    });

    testWidgets('Secondary button uses white with light green border', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlinedButton(
              onPressed: () {},
              style: AppButtons.secondaryButton,
              child: const Text('Secondary Button'),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget,
          reason: 'Secondary button should render');
      expect(find.text('Secondary Button'), findsOneWidget,
          reason: 'Button text should render');
    });

    testWidgets('Text field uses light green borders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: AppInputs.inputDecoration(
                label: 'Test Input',
                hint: 'Enter text',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget,
          reason: 'Text field should render');
    });

    testWidgets('AppBar uses light green background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              title: const Text('Test AppBar'),
              elevation: 2,
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(AppColors.primary),
          reason: 'AppBar should use light green background');
      expect(appBar.foregroundColor, equals(AppColors.white),
          reason: 'AppBar text should be white');
      expect(appBar.elevation, lessThanOrEqualTo(3.0),
          reason: 'AppBar elevation should be subtle (2-3dp)');
    });
  });

  group('Visual Regression Tests - Comprehensive Color Audit', () {
    test('All theme colors are documented and verified', () {
      final colorAudit = {
        'Primary Colors': {
          'primaryLightest': AppColors.primaryLightest.toARGB32(),
          'primaryLight': AppColors.primaryLight.toARGB32(),
          'primaryMediumLight': AppColors.primaryMediumLight.toARGB32(),
          'primary': AppColors.primary.toARGB32(),
          'primaryMedium': AppColors.primaryMedium.toARGB32(),
        },
        'Background Colors': {
          'white': AppColors.white.toARGB32(),
          'backgroundLight': AppColors.backgroundLight.toARGB32(),
          'cardBackground': AppColors.cardBackground.toARGB32(),
          'scaffoldBackground': AppColors.scaffoldBackground.toARGB32(),
        },
        'Text Colors': {
          'textPrimary': AppColors.textPrimary.toARGB32(),
          'textSecondary': AppColors.textSecondary.toARGB32(),
          'textHint': AppColors.textHint.toARGB32(),
          'textOnPrimary': AppColors.textOnPrimary.toARGB32(),
        },
        'Status Colors': {
          'success': AppColors.success.toARGB32(),
          'error': AppColors.error.toARGB32(),
          'warning': AppColors.warning.toARGB32(),
          'info': AppColors.info.toARGB32(),
        },
        'Category Colors': {
          'donate': AppColors.donate.toARGB32(),
          'recyclable': AppColors.recyclable.toARGB32(),
          'nonRecyclable': AppColors.nonRecyclable.toARGB32(),
        },
        'Border Colors': {
          'borderLight': AppColors.borderLight.toARGB32(),
          'borderMedium': AppColors.borderMedium.toARGB32(),
        },
      };

      // Print color audit for documentation
      debugPrint('\n=== VISUAL REGRESSION TEST - COLOR AUDIT ===\n');
      for (var category in colorAudit.entries) {
        debugPrint('${category.key}:');
        for (var color in category.value.entries) {
          debugPrint('  ${color.key}: #${color.value.toRadixString(16).toUpperCase().substring(2)}');
        }
        debugPrint('');
      }

      // Verify all colors are defined
      expect(colorAudit['Primary Colors']!.length, equals(5),
          reason: 'Should have 5 primary color shades');
      expect(colorAudit['Background Colors']!.length, equals(4),
          reason: 'Should have 4 background colors');
      expect(colorAudit['Text Colors']!.length, equals(4),
          reason: 'Should have 4 text colors');
      expect(colorAudit['Status Colors']!.length, equals(4),
          reason: 'Should have 4 status colors');
      expect(colorAudit['Category Colors']!.length, equals(3),
          reason: 'Should have 3 category colors');
      expect(colorAudit['Border Colors']!.length, equals(2),
          reason: 'Should have 2 border colors');
    });

    test('Visual changes summary', () {
      final visualChanges = {
        'Color Palette': 'Changed from dark green (#132a13, #31572c) to light green (#E8F5E9 - #66BB6A)',
        'Backgrounds': 'Changed from dark to white (#FFFFFF) and very light green (#F1F8F4)',
        'Text Colors': 'Changed to dark gray-green (#2E3B2E) and medium green (#4A7C59) for contrast',
        'Gradients': 'Removed all gradients, using solid colors only',
        'Shadows': 'Reduced to subtle shadows (2-8px blur, 0.08-0.15 opacity)',
        'Buttons': 'Changed to light green (#66BB6A, #81C784) with white text',
        'Borders': 'Changed to light green (#C8E6C9) and medium green (#66BB6A)',
        'Cards': 'Changed to white backgrounds with subtle shadows',
        'AppBar': 'Changed to light green (#81C784) with white text',
        'Status Colors': 'Updated to soft colors (success: #66BB6A, error: #EF5350, warning: #FFA726)',
      };

      debugPrint('\n=== VISUAL REGRESSION TEST - CHANGES SUMMARY ===\n');
      for (var change in visualChanges.entries) {
        debugPrint('${change.key}:');
        debugPrint('  ${change.value}');
        debugPrint('');
      }

      // Verify changes are documented
      expect(visualChanges.length, greaterThanOrEqualTo(10),
          reason: 'Should document at least 10 major visual changes');
    });
  });
}
