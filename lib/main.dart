import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_page.dart';
import 'firebase_options.dart';
import 'screens/profile/profile_page.dart';
import 'screens/profile/profile_setup_page.dart';
import 'screens/seller/seller_dashboard1.dart';
import 'screens/buyer/buyer_dashboard1.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Flag to track if user has manually logged out
bool _userLoggedOut = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Check if user has manually logged out
    final prefs = await SharedPreferences.getInstance();
    _userLoggedOut = prefs.getBool('user_logged_out') ?? false;

    // If user manually logged out, sign out from Firebase too
    if (_userLoggedOut) {
      await FirebaseAuth.instance.signOut();
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JunkWunk',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If user manually logged out or no user data, show login page
          if (_userLoggedOut || !snapshot.hasData || snapshot.data == null) {
            return const LoginPage();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const LoginPage();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

              // Check if user has a role
              if (!userData.containsKey('role')) {
                return ProfileSetupPage(
                  email: snapshot.data!.email ?? '',
                );
              }

              final userRole = userData['role'] as String;

              // Check if profile is completed
              if (!userData.containsKey('profileCompleted') ||
                  userData['profileCompleted'] == false) {
                // Navigate to profile setup if profile is not completed
                return ProfileSetupPage(
                  email: snapshot.data!.email ?? '',
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
        '/login': (context) => const LoginPage(),
        '/seller/dashboard': (context) => _buildDashboard('seller'),
        '/buyer/dashboard': (context) => _buildDashboard('buyer'),
        '/profile': (context) => ProfileUI(), // Directly using ProfileUI
        '/profile/setup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ProfileSetupPage(
            email: args?['email'] ??
                FirebaseAuth.instance.currentUser?.email ??
                '',
            role: args?['role'],
          );
        },
      },
    );
  }
}

// Add a function to handle logout that sets the flag
Future<void> handleLogout(BuildContext context) async {
  try {
    // Set flag that user has manually logged out
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_out', true);
    _userLoggedOut = true;

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Navigate to login page
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    print('Error during logout: $e');
  }
}

Widget _buildDashboard(String role) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const LoginPage();
      }
      return role == 'seller' ? SellerDashboard1() : BuyerDashboard1();
    },
  );
}
