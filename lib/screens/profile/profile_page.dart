import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../utils/custom_toast.dart';
import '../../widgets/app_bar.dart';
import '../login_page.dart';
import 'edit_profile_page.dart';

class ProfileUI extends StatefulWidget {
  const ProfileUI({super.key});

  @override
  ProfileUIState createState() => ProfileUIState();
}

class ProfileUIState extends State<ProfileUI> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

  // App theme colors
  final Color primaryColor = const Color(0xFF371f97);
  final Color accentColor = const Color(0xFFf5f5f5);

  // User info variables
  String userType = "";
  String name = "";
  String email = "";
  String phone = "";
  String location = "";
  bool isVerifiedByNGO = true;
  int creditPoints = 50; // Default credit points

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userData.exists) {
          setState(() {
            Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
            userType = data['role'] ?? "";
            name = data['displayName'] ?? "";
            email = currentUser.email ?? "";
            phone = data['phone'] ?? "";
            location = data['location'] ?? "";
            if (data['role']?.toLowerCase() == 'buyer') {
              isVerifiedByNGO = true;
              creditPoints =
                  data['creditPoints'] ?? 50; // Load credits or use default
            } else {
              isVerifiedByNGO = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (!mounted) return;
      CustomToast.showError(context, 'Error loading profile data');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          name: name,
          email: email,
          phone: phone,
          location: location,
        ),
      ),
    );

    if (result != null) {
      try {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'displayName': result["name"],
            'phone': result["phone"],
            'location': result["location"],
          });

          await _loadUserData();
        }
      } catch (e) {
        debugPrint('Error updating user data: $e');
        if (!mounted) return;
        CustomToast.showError(context, 'Error updating profile');
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.9),
                  primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: primaryColor,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _signOut(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade400,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: 'My Profile',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 16),
            if (userType.toLowerCase() == 'buyer') _buildVerificationCard(),
            _buildInfoCard('Email', email, Icons.email_rounded, Colors.blue),
            _buildInfoCard('Phone', phone, Icons.phone_rounded, Colors.green),
            _buildInfoCard(
                'Location', location, Icons.location_on_rounded, Colors.orange),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditPage,
        backgroundColor: primaryColor,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top header with credits for buyers
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (userType.toLowerCase() == 'buyer')
                Tooltip(
                  message:
                      'Earn more credits by:\n• Making donations\n• Referring friends\n• Participating in events',
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(color: Colors.white),
                  child: Container(
                    margin: EdgeInsets.only(top: 16, right: 16),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$creditPoints pts',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          // Profile picture
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.8), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 70,
                    color: primaryColor,
                  ),
                ),
              ),
              if (userType.toLowerCase() == 'buyer')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          // Name
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // User type badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: userType.toLowerCase() == "seller"
                  ? Colors.green[600]
                  : Colors.blue[600],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              userType.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    if (userType.toLowerCase() != 'buyer') {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.05),
              Colors.green.withValues(alpha: 0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.green,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NGO Verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Verified by NGO Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color iconColor) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : 'Not provided',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
