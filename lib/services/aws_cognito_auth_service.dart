import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';

import 'aws_config.dart';

/// AWS Cognito Authentication Service
/// Handles user authentication using AWS Cognito User Pool
class AWSCognitoAuthService {
  late CognitoUserPool _userPool;
  CognitoUser? _currentUser;
  CognitoUserSession? _session;

  AWSCognitoAuthService() {
    _userPool = CognitoUserPool(
      AWSConfig.userPoolId,
      AWSConfig.clientId,
    );
  }

  /// Sign up a new user with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AWS Cognito: Starting signup for $email');

      final userAttributes = [
        AttributeArg(name: 'email', value: email),
      ];

      final result = await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );

      debugPrint('AWS Cognito: Signup successful');

      return {
        'success': true,
        'userConfirmed': result.userConfirmed ?? false,
        'userId': result.userSub,
        'message': 'Account created successfully',
      };
    } catch (e) {
      debugPrint('AWS Cognito: Signup error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AWS Cognito: Starting sign in for $email');

      _currentUser = CognitoUser(
        email,
        _userPool,
      );

      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );

      _session = await _currentUser!.authenticateUser(authDetails);

      if (_session == null || !_session!.isValid()) {
        return {
          'success': false,
          'message': 'Authentication failed - invalid session',
        };
      }

      debugPrint('AWS Cognito: Sign in successful');

      return {
        'success': true,
        'userId': _session!.getIdToken().getJwtToken(),
        'email': email,
        'accessToken': _session!.getAccessToken().getJwtToken(),
        'refreshToken': _session!.getRefreshToken()?.getToken(),
      };
    } catch (e) {
      debugPrint('AWS Cognito: Sign in error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        await _currentUser!.signOut();
        _currentUser = null;
        _session = null;
        debugPrint('AWS Cognito: Sign out successful');
      }
    } catch (e) {
      debugPrint('AWS Cognito: Sign out error - $e');
    }
  }

  /// Get current user session
  Future<CognitoUserSession?> getCurrentSession() async {
    try {
      if (_currentUser == null) {
        return null;
      }

      _session = await _currentUser!.getSession();
      return _session;
    } catch (e) {
      debugPrint('AWS Cognito: Get session error - $e');
      return null;
    }
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await getCurrentSession();
      return session != null && session.isValid();
    } catch (e) {
      return false;
    }
  }

  /// Get current user attributes
  Future<Map<String, dynamic>?> getUserAttributes() async {
    try {
      if (_currentUser == null) {
        return null;
      }

      final attributes = await _currentUser!.getUserAttributes();
      if (attributes == null) {
        return null;
      }

      final Map<String, dynamic> attributesMap = {};
      for (var attribute in attributes) {
        attributesMap[attribute.name!] = attribute.value!;
      }

      return attributesMap;
    } catch (e) {
      debugPrint('AWS Cognito: Get attributes error - $e');
      return null;
    }
  }

  /// Initiate password reset
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      debugPrint('AWS Cognito: Initiating password reset for $email');

      final cognitoUser = CognitoUser(
        email,
        _userPool,
      );

      await cognitoUser.forgotPassword();

      return {
        'success': true,
        'message': 'Password reset code sent to your email',
      };
    } catch (e) {
      debugPrint('AWS Cognito: Forgot password error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Confirm password reset with code
  Future<Map<String, dynamic>> confirmPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    try {
      debugPrint('AWS Cognito: Confirming password reset for $email');

      final cognitoUser = CognitoUser(
        email,
        _userPool,
      );

      await cognitoUser.confirmPassword(confirmationCode, newPassword);

      return {
        'success': true,
        'message': 'Password reset successful',
      };
    } catch (e) {
      debugPrint('AWS Cognito: Confirm password error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Confirm user registration with verification code
  Future<Map<String, dynamic>> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      debugPrint('AWS Cognito: Confirming registration for $email');

      final cognitoUser = CognitoUser(
        email,
        _userPool,
      );

      await cognitoUser.confirmRegistration(confirmationCode);

      return {
        'success': true,
        'message': 'Email verified successfully',
      };
    } catch (e) {
      debugPrint('AWS Cognito: Confirm registration error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Resend confirmation code
  Future<Map<String, dynamic>> resendConfirmationCode({
    required String email,
  }) async {
    try {
      debugPrint('AWS Cognito: Resending confirmation code for $email');

      final cognitoUser = CognitoUser(
        email,
        _userPool,
      );

      await cognitoUser.resendConfirmationCode();

      return {
        'success': true,
        'message': 'Verification code sent to your email',
      };
    } catch (e) {
      debugPrint('AWS Cognito: Resend confirmation code error - $e');
      return {
        'success': false,
        'message': _parseError(e.toString()),
      };
    }
  }

  /// Get current user ID (sub claim from token) - synchronous version
  String? getCurrentUserId() {
    try {
      if (_session == null || !_session!.isValid()) {
        return null;
      }
      return _session!.getIdToken().decodePayload()['sub'];
    } catch (e) {
      debugPrint('AWS Cognito: Get user ID error - $e');
      return null;
    }
  }

  /// Get current user ID asynchronously (retrieves from session if available)
  Future<String?> getCurrentUserIdAsync() async {
    try {
      // First try from current session
      if (_session != null && _session!.isValid()) {
        return _session!.getIdToken().decodePayload()['sub'];
      }

      // Try to get session from current user
      if (_currentUser != null) {
        _session = await _currentUser!.getSession();
        if (_session != null && _session!.isValid()) {
          return _session!.getIdToken().decodePayload()['sub'];
        }
      }

      return null;
    } catch (e) {
      debugPrint('AWS Cognito: Get user ID async error - $e');
      return null;
    }
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    try {
      if (_session == null || !_session!.isValid()) {
        return null;
      }
      return _session!.getIdToken().decodePayload()['email'];
    } catch (e) {
      debugPrint('AWS Cognito: Get user email error - $e');
      return null;
    }
  }

  /// Parse error messages to user-friendly format
  String _parseError(String error) {
    if (error.contains('UserNotFoundException')) {
      return 'No account exists with this email';
    } else if (error.contains('NotAuthorizedException')) {
      return 'Incorrect email or password';
    } else if (error.contains('UsernameExistsException')) {
      return 'An account already exists with this email';
    } else if (error.contains('InvalidPasswordException')) {
      return 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character';
    } else if (error.contains('InvalidParameterException')) {
      return 'Invalid email or password format';
    } else if (error.contains('CodeMismatchException')) {
      return 'Invalid verification code';
    } else if (error.contains('ExpiredCodeException')) {
      return 'Verification code has expired';
    } else if (error.contains('LimitExceededException')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('UserNotConfirmedException') ||
        error.contains('User Confirmation Necessary')) {
      return 'Please verify your email before signing in';
    } else if (error.contains('NetworkError') || error.contains('Connection')) {
      return 'No internet connection. Please check your network';
    }

    // Return generic error message
    return 'An error occurred. Please try again';
  }

  /// Refresh the current session
  Future<bool> refreshSession() async {
    try {
      if (_currentUser == null || _session == null) {
        return false;
      }

      final refreshToken = _session!.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      _session = await _currentUser!.refreshSession(refreshToken);
      return _session != null && _session!.isValid();
    } catch (e) {
      debugPrint('AWS Cognito: Refresh session error - $e');
      return false;
    }
  }

  /// Initialize user from stored credentials
  Future<bool> initializeUser(String email) async {
    try {
      _currentUser = CognitoUser(
        email,
        _userPool,
      );

      _session = await _currentUser!.getSession();
      return _session != null && _session!.isValid();
    } catch (e) {
      debugPrint('AWS Cognito: Initialize user error - $e');
      return false;
    }
  }
}
