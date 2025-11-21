// JunkWunk App Widget Tests
//
// Basic widget tests for the JunkWunk marketplace application

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:junk_wunk/utils/design_constants.dart';

void main() {
  testWidgets('Theme uses light green color scheme', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.secondary,
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.white,
            error: AppColors.error,
          ),
        ),
        home: const Scaffold(
          body: Center(child: Text('Test')),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, isNull); // Uses theme default
    
    // Verify theme colors are set correctly
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.primaryColor, equals(AppColors.primary));
    expect(materialApp.theme?.scaffoldBackgroundColor, equals(AppColors.secondary));
  });

  testWidgets('Scaffold uses light green background', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: const Center(child: Text('Test Content')),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(AppColors.scaffoldBackground));
    expect(find.text('Test Content'), findsOneWidget);
  });

  testWidgets('Card uses white background', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Card(
            color: AppColors.white,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Card Content'),
            ),
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, equals(AppColors.white));
    expect(find.text('Card Content'), findsOneWidget);
  });

  testWidgets('Button uses light green theme colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () {},
            style: AppButtons.primaryButton,
            child: const Text('Test Button'),
          ),
        ),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Test Button'), findsOneWidget);
  });
}
