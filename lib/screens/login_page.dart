import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_helpers.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Duration get loadingTime => const Duration(milliseconds: 2000);

  // Authentication and validation methods remain the same
  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String?> _authUser(LoginData data) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(data.name)) {
        return 'Please enter a valid email address';
      }

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );

      if (userCredential.user == null) {
        return 'Authentication failed';
      }

      // Reset the user_logged_out flag when login is successful
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_out', false);

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account exists with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return e.message ?? 'Authentication failed';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<String?> _signUpUser(SignupData data) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      if (!_validatePassword(data.password!)) {
        return 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character';
      }

      print('DEBUG: Starting signup process for ${data.name}');

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );

      print('DEBUG: User created with UID: ${userCredential.user?.uid}');

      // Create user document (removed emailVerified field)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': data.name!,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('DEBUG: User document created in Firestore');

      // Reset the user_logged_out flag when signup is successful
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_out', false);

      // Force update auth state to avoid loading issue
      await userCredential.user?.reload();
      print('DEBUG: User auth state reloaded');

      return null;
    } on FirebaseAuthException catch (e) {
      print(
          'DEBUG: FirebaseAuthException during signup: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Invalid email format';
        case 'weak-password':
          return 'Password is too weak';
        default:
          return e.message ?? 'Sign up failed';
      }
    } catch (e) {
      print('DEBUG: Unexpected error during signup: $e');
      return 'An unexpected error occurred: $e';
    }
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      if (!await _checkConnectivity()) {
        return 'No internet connection. Please check your network.';
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account exists with this email';
        case 'invalid-email':
          return 'Invalid email format';
        default:
          return e.message ?? 'Password recovery failed';
      }
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
          primaryColor: const Color(0xFF371f97), // Dark purple
          accentColor: const Color(0xFFEEE8F6), // Light lavender
          errorColor: Colors.redAccent,
          pageColorLight: const Color(0xFFEEE8F6), // Light lavender
          pageColorDark: const Color(0xFF371f97), // Dark purple
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF371f97),
            elevation: 8,
          ),
          bodyStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFFEEE8F6),
          ),
          textFieldStyle: const TextStyle(
            color: Colors.white,
          ),
          buttonStyle: const TextStyle(
            color: Color(0xFF371f97),
          ),
          buttonTheme: LoginButtonTheme(
            backgroundColor: const Color(0xFFEEE8F6),
            highlightColor: const Color(0xFFFFFFFF),
            elevation: 5.0,
          ),
          inputTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFEEE8F6).withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFEEE8F6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFEEE8F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
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
        loginProviders: [
          LoginProvider(
              icon: Icons.g_mobiledata,
              label: 'Google',
              callback: () async {
                try {
                  // First check if there's a previously signed-in account
                  final GoogleSignIn googleSignIn = GoogleSignIn();

                  // Sign out first to force the account picker
                  await googleSignIn.signOut();

                  // Now show the account picker
                  final GoogleSignInAccount? googleUser =
                      await googleSignIn.signIn();

                  if (googleUser == null) return 'Google sign-in cancelled';

                  final GoogleSignInAuthentication googleAuth =
                      await googleUser.authentication;
                  final credential = GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );

                  // Sign in with Firebase
                  final userCredential = await FirebaseAuth.instance
                      .signInWithCredential(credential);

                  if (userCredential.user != null) {
                    // Check if this is a new user
                    if (userCredential.additionalUserInfo?.isNewUser == true) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .set({
                        'email': userCredential.user!.email,
                        'displayName': userCredential.user!.displayName,
                        'photoURL': userCredential.user!.photoURL,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    // Reset the user_logged_out flag when Google sign-in is successful
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('user_logged_out', false);

                    if (context.mounted) {
                      // Use the helper method to handle navigation
                      await AuthHelpers.handlePostAuthNavigation(context);
                    }
                  }

                  return null;
                } catch (e) {
                  return 'Google sign-in failed: ${e.toString()}';
                }
              }),
        ],
        onSubmitAnimationCompleted: () {
          print('DEBUG: Login/Signup animation completed');

          // Get the current user directly
          final User? user = FirebaseAuth.instance.currentUser;

          if (user != null && context.mounted) {
            // Reset logout flag
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('user_logged_out', false);
            });

            // Navigate immediately without delay
            AuthHelpers.handlePostAuthNavigation(context);
          } else {
            print('DEBUG: User is null after animation completion');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Authentication issue. Please try again.')),
              );
            }
          }
        },
      ),
    );
  }
}
