import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../utils/colors.dart' as colors;
import 'edit_profile_page.dart';

class ProfileUI extends StatefulWidget {
  const ProfileUI({super.key});

  @override
  ProfileUIState createState() => ProfileUIState();
}

class ProfileUIState extends State<ProfileUI> {
  String? _userId;
  String? _userEmail;

  // App theme colors from centralized colors.dart
  final Color primaryColor = colors.AppColors.primaryColor;
  final Color accentColor = colors.AppColors.lightAccent;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('cognito_user_id');
      _userEmail = prefs.getString('cognito_user_email');
    });
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    if (_userId == null) return null;
    return await ApiService.getUser(_userId!);
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colors.AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colors.AppColors.white,
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
                    color: colors.AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colors.AppColors.primaryMedium,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: colors.AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.AppColors.textSecondary,
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
                          foregroundColor: colors.AppColors.primaryMedium,
                          backgroundColor: colors.AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colors.AppColors.borderLight,
                              width: 2,
                            ),
                          ),
                          elevation: 0,
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
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Logout and clear session
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('user_logged_out', true);
                          await prefs.remove('cognito_user_email');
                          await prefs.remove('cognito_user_id');

                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: colors.AppColors.white,
                          backgroundColor: colors.AppColors.primaryMedium,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
    // Use stored userId from Cognito
    if (_userId == null || _userId!.isEmpty) {
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: primaryColor,
            ),
            body: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

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
        String email = _userEmail ?? "";
        String phone = "";
        String location = "";
        bool isVerifiedByNGO = true;
        int creditPoints = 50;

        if (snapshot.hasData && snapshot.data != null) {
          Map<String, dynamic> data = snapshot.data!;
          debugPrint('Profile data received: $data');
          userType = data['role'] ?? "";
          name = data['displayName'] ?? "";
          phone = data['phone'] ?? "";
          location = data['location'] ?? "";
          debugPrint('Extracted - phone: $phone, location: $location');
          if (data['role']?.toLowerCase() == 'buyer') {
            isVerifiedByNGO = true;
            final points = data['creditPoints'] ?? 50;
            creditPoints = (points is int ? points : (points as num).toInt());
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
                color: colors.AppColors.white, // White on colored background
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
                    // Refresh the profile data after returning from edit page
                    setState(() {});
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 26),
                color: colors.AppColors.white, // White on colored background
                onPressed: () => _showLogoutConfirmation(context),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Trigger a rebuild to fetch fresh data
              setState(() {});
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
        _buildInfoCard(
            'Email', email, Icons.email_rounded, colors.AppColors.primary),
        _buildInfoCard(
            'Phone', phone, Icons.phone_rounded, colors.AppColors.primary),
        _buildInfoCard('Location', location, Icons.location_on_rounded,
            colors.AppColors.primary),
      ],
    );
  }

  Widget _buildProfileHeader({
    required String userType,
    required String name,
    required int creditPoints,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Top header with credits for buyers
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (userType.toLowerCase() == 'buyer')
                Container(
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.AppColors.primary, // Light green background
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: colors.AppColors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$creditPoints pts',
                        style: TextStyle(
                          color: colors.AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Profile picture with white circle background
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: colors.AppColors.primaryLightest,
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: colors.AppColors.primary,
                  ),
                ),
              ),
              if (userType.toLowerCase() == 'buyer')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colors.AppColors.primaryMedium, // Medium green
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: colors.AppColors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: colors.AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Name - using text primary color
          Text(
            name,
            style: TextStyle(
              color: colors.AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          // User type badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colors.AppColors.primaryMedium, // Medium green for both
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              userType.toUpperCase(),
              style: TextStyle(
                color: colors.AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
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
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colors.AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.verified_user_rounded,
                color: colors.AppColors.primaryMedium,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NGO Verification',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verified by NGO Partner',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.AppColors.primaryMedium,
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
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colors.AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.AppColors.primary, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : 'Not provided',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.AppColors.textPrimary,
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
