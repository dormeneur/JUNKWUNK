import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelpers {
  /// Helper method to handle post-authentication navigation
  static Future<void> handlePostAuthNavigation(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication issue. Please sign in again.')),
        );
        return;
      }

      // Reset the user_logged_out flag when navigation happens after login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_out', false);

      try {
        // Check if user document exists
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // If user document doesn't exist yet, create one with basic info
        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'profileCompleted': false, // Explicitly mark as incomplete
          }, SetOptions(merge: true));
        }

        // Get the latest user data after possible creation
        final latestUserDoc = !userDoc.exists
            ? await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get()
            : userDoc;

        final userData = latestUserDoc.data();

        // Check if user has a role and completed profile
        if (userData != null &&
            userData.containsKey('role') &&
            userData.containsKey('profileCompleted') &&
            userData['profileCompleted'] == true) {
          // User has completed profile, navigate to dashboard
          final userRole = userData['role'] as String;

          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              userRole == 'seller' ? '/seller/dashboard' : '/buyer/dashboard',
              (Route<dynamic> route) => false,
            );
          }
        } else {
          // User profile is incomplete - direct to profile setup page
          String? existingRole;
          if (userData != null && userData.containsKey('role')) {
            existingRole = userData['role'] as String?;
          }

          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/profile/setup',
              (Route<dynamic> route) => false,
              arguments: {'email': user.email, 'role': existingRole},
            );
          }
        }
      } catch (firestoreError) {
        // Handle Firestore errors by proceeding to profile setup
        print('Firestore error in handlePostAuthNavigation: $firestoreError');

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/profile/setup',
            (Route<dynamic> route) => false,
            arguments: {'email': user.email, 'role': null},
          );
        }
      }
    } catch (e) {
      print('Error in handlePostAuthNavigation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );

        // Fallback to profile setup if there's an error
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/profile/setup',
          (Route<dynamic> route) => false,
          arguments: {
            'email': FirebaseAuth.instance.currentUser?.email ?? '',
            'role': null
          },
        );
      }
    }
  }
}
