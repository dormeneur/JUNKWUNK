import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_page.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'firebase_options.dart';
import 'screens/profile/profile_page.dart';
import 'screens/seller/seller_dashboard1.dart';
import 'screens/buyer/buyer_dashboard1.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hackathon App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
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

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;

              if (!userData.containsKey('role')) {
                return const LoginPage(); // Ensure role selection before dashboard access
              }

              final userRole = userData['role'] as String;
              print("Current User Role: $userRole"); // Debugging role assignment

              return userRole == 'seller' ? SellerDashboard1() : BuyerDashboard1();
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/seller/dashboard': (context) => _buildDashboard('seller'),
        '/buyer/dashboard': (context) => _buildDashboard('buyer'),
        '/profile': (context) => ProfileUI(), // Directly using ProfileUI
      },
    );
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
