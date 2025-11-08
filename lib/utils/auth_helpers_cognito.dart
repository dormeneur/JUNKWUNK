import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'custom_toast.dart';

/// Auth Helpers for AWS Cognito
/// Modified to work with Cognito instead of Firebase Auth
class AuthHelpersCognito {
  /// Helper method to handle post-authentication navigation
  static Future<void> handlePostAuthNavigation(
    BuildContext context, {
    String? userId,
    String? email,
  }) async {
    if (!context.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Use provided email or get from SharedPreferences
      final userEmail = email ?? prefs.getString('cognito_user_email');

      if (userEmail == null) {
        CustomToast.showError(
            context, 'Authentication issue. Please sign in again.');
        return;
      }

      // Use provided userId or show error
      if (userId == null) {
        CustomToast.showError(context, 'Failed to get user information.');
        return;
      }

      // Reset the user_logged_out flag when navigation happens after login
      await prefs.setBool('user_logged_out', false);

      try {
        // Check if user exists via API
        final userData = await ApiService.getUser(userId);

        // If user doesn't exist yet, create one with basic info
        if (userData == null) {
          await ApiService.updateUser(userId, {
            'email': userEmail,
            'createdAt': DateTime.now().toIso8601String(),
            'profileCompleted': false, // Explicitly mark as incomplete
            'authProvider': 'cognito',
          });
        }

        // Get the latest user data after possible creation
        final latestUserData = userData ?? await ApiService.getUser(userId);

        // Check if user has a role and completed profile
        if (latestUserData != null &&
            latestUserData.containsKey('role') &&
            latestUserData.containsKey('profileCompleted') &&
            latestUserData['profileCompleted'] == true) {
          // User has completed profile, navigate to dashboard
          final userRole = latestUserData['role'] as String;

          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              userRole == 'seller' ? '/seller/dashboard' : '/buyer/dashboard',
              (Route<dynamic> route) => false,
            );
          }
        } else {
          // User profile is incomplete - direct to profile setup page
          String? existingRole;
          if (latestUserData != null && latestUserData.containsKey('role')) {
            existingRole = latestUserData['role'] as String?;
          }

          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/profile/setup',
              (Route<dynamic> route) => false,
              arguments: {'email': userEmail, 'role': existingRole},
            );
          }
        }
      } catch (apiError) {
        // Handle API errors by proceeding to profile setup
        debugPrint('API error in handlePostAuthNavigation: $apiError');

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/profile/setup',
            (Route<dynamic> route) => false,
            arguments: {'email': userEmail, 'role': null},
          );
        }
      }
    } catch (e) {
      debugPrint('Error in handlePostAuthNavigation: $e');
      if (context.mounted) {
        CustomToast.showError(context, 'Error: $e');

        // Fallback to profile setup if there's an error
        final prefs = await SharedPreferences.getInstance();
        final fallbackEmail = prefs.getString('cognito_user_email') ?? '';

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/profile/setup',
          (Route<dynamic> route) => false,
          arguments: {'email': fallbackEmail, 'role': null},
        );
      }
    }
  }
}
