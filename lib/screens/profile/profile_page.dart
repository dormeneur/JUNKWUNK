import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart' as main_app;
import '../../utils/colors.dart' as colors;
import 'edit_profile_page.dart';

class ProfileUI extends StatefulWidget {
  const ProfileUI({super.key});

  @override
  ProfileUIState createState() => ProfileUIState();
}

class ProfileUIState extends State<ProfileUI> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App theme colors from centralized colors.dart
  final Color primaryColor = colors.AppColors.primaryColor;
  final Color accentColor = colors.AppColors.lightAccent;

  @override
  void initState() {
    super.initState();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF132a13), // Dark green
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF132a13), // Dark green background
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
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
                    color: const Color(0xFFecf39e), // Mindaro
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
                    color: Colors.white.withValues(alpha: 0.8),
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
                          foregroundColor: const Color(0xFF666666),
                          backgroundColor: const Color(0xFFecf39e), // Mindaro
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
                          main_app.handleLogout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFFF3D00),
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

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text('Not logged in'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: primaryColor,
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        // Default values while loading or if no data
        String userType = "";
        String name = "";
        String email = currentUser.email ?? "";
        String phone = "";
        String location = "";
        bool isVerifiedByNGO = true;
        int creditPoints = 50;

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          userType = data['role'] ?? "";
          name = data['displayName'] ?? "";
          phone = data['phone'] ?? "";
          location = data['location'] ?? "";
          if (data['role']?.toLowerCase() == 'buyer') {
            isVerifiedByNGO = true;
            creditPoints = data['creditPoints'] ?? 50;
          } else {
            isVerifiedByNGO = false;
          }
        }

        return Scaffold(
          backgroundColor: colors.AppColors.scaffoldBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        name: name,
                        email: email,
                        phone: phone,
                        location: location,
                      ),
                    ),
                  ).then((_) {
                    // StreamBuilder will automatically update when data changes
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 26),
                onPressed: () => _showLogoutConfirmation(context),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder automatically refreshes, but we can trigger a manual refresh if needed
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: _buildProfileContent(
              userType: userType,
              name: name,
              email: email,
              phone: phone,
              location: location,
              isVerifiedByNGO: isVerifiedByNGO,
              creditPoints: creditPoints,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent({
    required String userType,
    required String name,
    required String email,
    required String phone,
    required String location,
    required bool isVerifiedByNGO,
    required int creditPoints,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildProfileHeader(
          userType: userType,
          name: name,
          creditPoints: creditPoints,
        ),
        const SizedBox(height: 16),
        if (userType.toLowerCase() == 'buyer')
          _buildVerificationCard(isVerifiedByNGO),
        _buildInfoCard('Email', email, Icons.email_rounded,
            const Color(0xFF31572c)), // Hunter green
        _buildInfoCard('Phone', phone, Icons.phone_rounded,
            const Color(0xFF4f772d)), // Fern green
        _buildInfoCard('Location', location, Icons.location_on_rounded,
            const Color(0xFF90a955)), // Moss green
      ],
    );
  }

  Widget _buildProfileHeader({
    required String userType,
    required String name,
    required int creditPoints,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
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
                    margin: EdgeInsets.only(right: 16),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF90a955), // Moss green
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

          // Profile picture with white circle background
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: Offset(0, 8),
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
                      color: const Color(0xFF4f772d), // Fern green
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

          // Name - dark green on sage background
          Text(
            name,
            style: TextStyle(
              color: primaryColor, // Dark green
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // User type badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: userType.toLowerCase() == "seller"
                  ? const Color(0xFF4f772d) // Fern green for seller
                  : const Color(0xFF31572c), // Hunter green for buyer
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

  Widget _buildVerificationCard(bool isVerifiedByNGO) {
    if (!isVerifiedByNGO) {
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
                      color: const Color(
                          0xFF4f772d), // Fern green - matches palette
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
