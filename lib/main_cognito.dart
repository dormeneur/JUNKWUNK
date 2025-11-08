import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/buyer/buyer_dashboard1.dart';
import 'screens/login_page_cognito.dart';
import 'screens/profile/profile_page.dart';
import 'screens/profile/profile_setup_page.dart';
import 'screens/seller/seller_dashboard1.dart';
import 'services/aws_cognito_auth_service.dart';
import 'utils/design_constants.dart';

bool _userLoggedOut = false;
String? _cognitoUserEmail;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded from .env");

    // Initialize Firebase (still needed for Firestore)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully (Firestore only)");

    // Check if user has manually logged out
    final prefs = await SharedPreferences.getInstance();
    _userLoggedOut = prefs.getBool('user_logged_out') ?? false;
    _cognitoUserEmail = prefs.getString('cognito_user_email');

    debugPrint("User logged out: $_userLoggedOut");
    debugPrint("Cognito user email: $_cognitoUserEmail");
  } catch (e) {
    debugPrint("Error initializing app: $e");
  }

  runApp(const MyAppCognito());
}

class MyAppCognito extends StatelessWidget {
  const MyAppCognito({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JunkWunk (AWS Cognito)',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.secondary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.white,
          error: AppColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppButtons.primaryButton,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.h1,
          displayMedium: AppTypography.h2,
          displaySmall: AppTypography.h3,
          headlineMedium: AppTypography.h4,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkCognitoAuth(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }

          // If user manually logged out or not authenticated, show login page
          if (_userLoggedOut || !snapshot.hasData || snapshot.data == false) {
            return const LoginPageCognito();
          }

          // User is authenticated, check Firestore profile
          return FutureBuilder<DocumentSnapshot>(
            future: _getUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // No profile found, show profile setup
                return ProfileSetupPage(
                  email: _cognitoUserEmail ?? '',
                );
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

              // Check if user has a role
              if (!userData.containsKey('role')) {
                return ProfileSetupPage(
                  email: _cognitoUserEmail ?? '',
                );
              }

              final userRole = userData['role'] as String;

              // Check if profile is completed
              if (!userData.containsKey('profileCompleted') ||
                  userData['profileCompleted'] == false) {
                return ProfileSetupPage(
                  email: _cognitoUserEmail ?? '',
                  role: userData['role'] as String?,
                );
              }

              // If profile is completed, navigate to dashboard
              return userRole == 'seller'
                  ? SellerDashboard1()
                  : BuyerDashboard1();
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginPageCognito(),
        '/seller/dashboard': (context) => _buildDashboard('seller'),
        '/buyer/dashboard': (context) => _buildDashboard('buyer'),
        '/profile': (context) => ProfileUI(),
        '/profile/setup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ProfileSetupPage(
            email: args?['email'] ?? _cognitoUserEmail ?? '',
            role: args?['role'],
          );
        },
      },
    );
  }

  // Check if user is authenticated with Cognito
  Future<bool> _checkCognitoAuth() async {
    try {
      if (_cognitoUserEmail == null || _cognitoUserEmail!.isEmpty) {
        return false;
      }

      // Just check if we have stored email, don't try to validate session on startup
      // Session validation will happen when needed
      return true;
    } catch (e) {
      debugPrint('Error checking Cognito auth: $e');
      return false;
    }
  }

  // Get user profile from Firestore using stored userId
  Future<DocumentSnapshot> _getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('cognito_user_id');

      if (userId == null) {
        throw Exception('No user ID found in storage');
      }

      return FirebaseFirestore.instance.collection('users').doc(userId).get();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }
}

// Add a function to handle logout that sets the flag
Future<void> handleLogoutCognito(BuildContext context) async {
  try {
    // Set flag that user has manually logged out
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_out', true);
    await prefs.remove('cognito_user_email');
    await prefs.remove('cognito_user_id'); // Clear userId as well
    _userLoggedOut = true;

    // Sign out from AWS Cognito
    final authService = AWSCognitoAuthService();
    await authService.signOut();

    debugPrint('AWS Cognito: User signed out');

    // Navigate to login page
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    debugPrint('Error during logout: $e');
  }
}

Widget _buildDashboard(String role) {
  return FutureBuilder<DocumentSnapshot>(
    future: () async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('cognito_user_id');

      if (userId == null) {
        throw Exception('No user ID found');
      }

      return FirebaseFirestore.instance.collection('users').doc(userId).get();
    }(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const LoginPageCognito();
      }
      return role == 'seller' ? SellerDashboard1() : BuyerDashboard1();
    },
  );
}
