import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/aws_cognito_auth_service.dart';
import '../services/api_service.dart';
import '../utils/auth_helpers_cognito.dart';
import '../utils/custom_toast.dart';
import 'email_verification_page.dart';

/// Login Page using AWS Cognito Authentication
/// This replaces Firebase Auth with AWS Cognito User Pool
class LoginPageCognito extends StatefulWidget {
  const LoginPageCognito({super.key});

  @override
  State<LoginPageCognito> createState() => _LoginPageCognitoState();
}

class _LoginPageCognitoState extends State<LoginPageCognito> {
  final AWSCognitoAuthService _authService = AWSCognitoAuthService();

  Duration get loadingTime => const Duration(milliseconds: 2000);

  // Password validation
  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Sign in with AWS Cognito
  Future<String?> _authUser(LoginData data) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(data.name)) {
        return 'Please enter a valid email address';
      }

      debugPrint('AWS Cognito: Attempting sign in');

      final result = await _authService.signIn(
        email: data.name,
        password: data.password,
      );

      if (!result['success']) {
        // Check if user needs to verify email
        if (result['message'].toString().contains('verify your email')) {
          // Navigate to email verification page
          if (mounted) {
            final verified = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: data.name,
                  password: data.password,
                ),
              ),
            );

            if (verified == true) {
              // User verified, retry login
              return await _authUser(data);
            }
          }
        }
        return result['message'];
      }

      // Store user email in SharedPreferences for session management
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cognito_user_email', data.name);
      await prefs.setBool('user_logged_out', false);

      // Store Cognito tokens for API calls
      await prefs.setString('cognito_id_token', result['userId']);
      await prefs.setString('cognito_access_token', result['accessToken']);
      if (result['refreshToken'] != null) {
        await prefs.setString('cognito_refresh_token', result['refreshToken']);
      }

      // Get user ID from Cognito
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        return 'Failed to get user information';
      }

      // Store userId for later use
      await prefs.setString('cognito_user_id', userId);

      debugPrint('AWS Cognito: Sign in successful, userId: $userId');

      // Check if user profile exists in DynamoDB via API
      final userData = await ApiService.getUser(userId);

      if (userData == null) {
        // Create user document in DynamoDB via API
        await ApiService.updateUser(userId, {
          'email': data.name,
          'createdAt': DateTime.now().toIso8601String(),
          'authProvider': 'cognito',
        });
        debugPrint('AWS Cognito: Created DynamoDB user document via API');
      }

      return null;
    } catch (e) {
      debugPrint('AWS Cognito: Sign in error - $e');
      return 'An unexpected error occurred';
    }
  }

  // Sign up with AWS Cognito
  Future<String?> _signUpUser(SignupData data) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      if (!_validatePassword(data.password!)) {
        return 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character';
      }

      debugPrint('AWS Cognito: Starting signup process for ${data.name}');

      final result = await _authService.signUp(
        email: data.name!,
        password: data.password!,
      );

      if (!result['success']) {
        return result['message'];
      }

      debugPrint('AWS Cognito: Signup successful, userId: ${result['userId']}');

      // Check if user needs email verification
      if (result['userConfirmed'] == false) {
        debugPrint('AWS Cognito: User needs email verification');

        // Navigate to email verification page
        if (mounted) {
          final verified = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                email: data.name!,
                password: data.password!,
              ),
            ),
          );

          if (verified == true) {
            // User verified email, now sign them in
            return await _authUser(LoginData(
              name: data.name!,
              password: data.password!,
            ));
          } else {
            return 'Please verify your email to continue';
          }
        }
        return 'Please verify your email to continue';
      }

      // If user is already confirmed, sign them in directly
      final signInResult = await _authService.signIn(
        email: data.name!,
        password: data.password!,
      );

      if (!signInResult['success']) {
        return 'Account created but sign in failed. Please try logging in.';
      }

      // Store user email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cognito_user_email', data.name!);
      await prefs.setBool('user_logged_out', false);

      // Store Cognito tokens for API calls
      await prefs.setString('cognito_id_token', signInResult['userId']);
      await prefs.setString(
          'cognito_access_token', signInResult['accessToken']);
      if (signInResult['refreshToken'] != null) {
        await prefs.setString(
            'cognito_refresh_token', signInResult['refreshToken']);
      }

      // Get user ID
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        return 'Account created but failed to get user information';
      }

      // Store userId for later use
      await prefs.setString('cognito_user_id', userId);

      // Create user document in DynamoDB via API
      await ApiService.updateUser(userId, {
        'email': data.name!,
        'createdAt': DateTime.now().toIso8601String(),
        'authProvider': 'cognito',
      });

      debugPrint('AWS Cognito: User document created in DynamoDB via API');

      return null;
    } catch (e) {
      debugPrint('AWS Cognito: Signup error - $e');
      return 'An unexpected error occurred: $e';
    }
  }

  // Initiate password recovery
  Future<String?> _recoverPassword(String email) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      debugPrint('AWS Cognito: Initiating password recovery for $email');

      final result = await _authService.forgotPassword(email: email);

      if (!result['success']) {
        return result['message'];
      }

      // Note: AWS Cognito sends a verification code to email
      // User will need to use that code to reset password
      return null;
    } catch (e) {
      debugPrint('AWS Cognito: Password recovery error - $e');
      return 'Password recovery failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        onLogin: _authUser,
        onSignup: _signUpUser,
        onRecoverPassword: _recoverPassword,
        title: 'JunkWunk',
        theme: LoginTheme(
          primaryColor: const Color(0xFF132a13), // Dark green
          accentColor: const Color(0xFFecf39e), // Mindaro
          errorColor: const Color(0xFFE53935),
          pageColorLight: const Color(0xFFecf39e), // Mindaro
          pageColorDark: const Color(0xFF132a13), // Dark green
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF31572c), // Hunter green
            elevation: 8,
          ),
          bodyStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFFFFFFFF), // White
          ),
          textFieldStyle: const TextStyle(
            color: Colors.white,
          ),
          buttonStyle: const TextStyle(
            color: Color(0xFF132a13), // Dark green
          ),
          buttonTheme: LoginButtonTheme(
            backgroundColor: const Color(0xFF90a955), // Moss green
            highlightColor: const Color(0xFFecf39e), // Mindaro
            elevation: 5.0,
          ),
          inputTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white70),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white70),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelStyle: const TextStyle(
              color: Colors.white,
            ),
            hintStyle: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
        messages: LoginMessages(
          userHint: 'Email',
          passwordHint: 'Password',
          confirmPasswordHint: 'Confirm Password',
          loginButton: 'SIGN IN',
          signupButton: 'SIGN UP',
          forgotPasswordButton: 'Forgot Password?',
          recoverPasswordButton: 'RECOVER',
          recoverPasswordIntro: 'Enter your email to receive a recovery code',
          recoverPasswordDescription:
              'We will send a verification code to your email',
          recoverPasswordSuccess: 'Recovery code sent! Check your email',
        ),
        onSubmitAnimationCompleted: () async {
          debugPrint('AWS Cognito: Login/Signup animation completed');

          try {
            // Get user ID and email from current session
            final userId = _authService.getCurrentUserId();
            final email = _authService.getCurrentUserEmail();

            if (userId == null || email == null) {
              debugPrint('AWS Cognito: Failed to get user info after login');
              if (context.mounted) {
                CustomToast.showError(
                    context, 'Authentication issue. Please try again.');
              }
              return;
            }

            // Reset logout flag
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('user_logged_out', false);
            await prefs.setString('cognito_user_email', email);

            debugPrint(
                'AWS Cognito: Navigating with userId: $userId, email: $email');

            // Navigate based on user profile
            if (context.mounted) {
              await AuthHelpersCognito.handlePostAuthNavigation(
                context,
                userId: userId,
                email: email,
              );
            }
          } catch (e) {
            debugPrint('AWS Cognito: Navigation error - $e');
            if (context.mounted) {
              CustomToast.showError(
                  context, 'An error occurred. Please try again.');
            }
          }
        },
      ),
    );
  }
}
