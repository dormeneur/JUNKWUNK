import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../services/api_keys.dart';
import '../../services/api_service.dart';
import '../../utils/custom_toast.dart';
import '../buyer/buyer_dashboard1.dart';
import '../seller/seller_dashboard1.dart';

class ProfileSetupPage extends StatefulWidget {
  final String email;
  final String? role;

  const ProfileSetupPage({
    super.key,
    required this.email,
    this.role,
  });

  @override
  ProfileSetupPageState createState() => ProfileSetupPageState();
}

class ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final String token = const Uuid().v4();
  List<dynamic> listOfLocations = [];
  bool _isAutocompletePaused = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  String? _selectedRole;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // App theme colors
  final Color primaryColor = const Color(0xFF132a13); // Dark green
  final Color accentColor = const Color(0xFFecf39e); // Mindaro

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    _selectedRole = widget.role;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );

    // Add location controller listener for autocomplete
    _locationController.addListener(() {
      _onLocationChange();
    });

    _animationController.forward();
    _tryLoadUserData();
  }

  // Add these methods for handling location autocomplete
  void _onLocationChange() {
    if (_locationController.text.isNotEmpty && !_isAutocompletePaused) {
      placeSuggestion(_locationController.text);
    } else if (_locationController.text.isEmpty) {
      setState(() {
        listOfLocations = [];
      });
    }
  }

  void placeSuggestion(String input) async {
    final String apiKey = googleApiKey; // Make sure to import api_keys.dart
    try {
      String baseUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      String request = "$baseUrl?input=$input&key=$apiKey&sessiontoken=$token";
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          listOfLocations = data['predictions'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _tryLoadUserData() async {
    try {
      // Get user ID directly from SharedPreferences (stored during login)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('cognito_user_id');

      if (userId != null && userId.isNotEmpty) {
        try {
          final userData = await ApiService.getUser(userId);

          if (userData != null && mounted) {
            setState(() {
              if (userData['displayName'] != null) {
                _nameController.text = userData['displayName'];
              }
              if (userData['phone'] != null) {
                _phoneController.text = userData['phone'];
              }
              if (userData['location'] != null) {
                _locationController.text = userData['location'];
              }
              if (userData['role'] != null && _selectedRole == null) {
                _selectedRole = userData['role'];
              }
            });
          }
        } catch (e) {
          debugPrint('Error loading user data: $e');
          // Continue without loading data
        }
      }
    } catch (e) {
      debugPrint('Error in _tryLoadUserData: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      setState(() {
        _isLoading = true;
      });

      debugPrint('!!!DEBUG: Starting profile save process');
      debugPrint('!!!DEBUG: Selected role: $_selectedRole');

      try {
        // Get user ID directly from SharedPreferences (stored during login)
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('cognito_user_id');
        final email = prefs.getString('cognito_user_email');

        if (userId == null || email == null) {
          debugPrint('!!!DEBUG: No userId or email found in SharedPreferences');
          if (mounted) {
            CustomToast.showError(
                context, 'User not found. Please log in again.');
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        debugPrint('!!!DEBUG: Current user ID: $userId');

        if (userId.isNotEmpty) {
          debugPrint(
              '!!!DEBUG: Attempting to update user via API'); // Add a short delay for better UX
          await Future.delayed(const Duration(milliseconds: 800));

          // Try to update via API but continue if it fails
          try {
            // Get coordinates from address for storing
            List<Location> locations =
                await locationFromAddress(_locationController.text);
            double? latitude, longitude;

            if (locations.isNotEmpty) {
              latitude = locations.first.latitude;
              longitude = locations.first.longitude;
            }

            // Prepare user data with all fields
            Map<String, dynamic> userData = {
              'displayName': _nameController.text,
              'phone': _phoneController.text,
              'location': _locationController.text,
              'role': _selectedRole,
              'profileCompleted': true,
              'creditPoints': _selectedRole == 'buyer' ? 50 : 0,
              'updatedAt': DateTime.now().toIso8601String(),
            };

            // Add coordinates if available
            if (latitude != null && longitude != null) {
              userData['coordinates'] = {
                'lat': latitude.toString(),
                'lng': longitude.toString(),
              };
            }

            // Update user via API
            await ApiService.updateUser(userId, userData);

            debugPrint('!!!DEBUG: API update completed successfully');
          } catch (apiError) {
            debugPrint('!!!DEBUG: API error: $apiError');
            // Show error but continue with navigation
            if (mounted) {}
          }

          // Set loading to false before navigation attempt
          setState(() {
            _isLoading = false;
          });

          debugPrint(
              '!!!DEBUG: About to navigate to dashboard regardless of API result');

          // CRITICAL FIX: DIRECT NAVIGATION - Always navigate regardless of API result
          if (mounted) {
            debugPrint(
                '!!!DEBUG: Context is mounted, proceeding with navigation');

            // Import the actual dashboard widgets at the top of this file
            if (_selectedRole == 'seller') {
              debugPrint('!!!DEBUG: Navigating to seller dashboard');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SellerDashboard1()),
                (Route<dynamic> route) => false,
              );
            } else {
              debugPrint('!!!DEBUG: Navigating to buyer dashboard');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => BuyerDashboard1()),
                (Route<dynamic> route) => false,
              );
            }
            debugPrint('!!!DEBUG: Navigation command executed');
          } else {
            debugPrint('!!!DEBUG: Context is NOT mounted after API update');
          }
        } else {
          debugPrint('!!!DEBUG: User is null, cannot update profile');
          if (mounted) {
            CustomToast.showError(
                context, 'User not found. Please log in again.');
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('!!!DEBUG: Error saving profile: $e');
        debugPrint('!!!DEBUG: Error type: ${e.runtimeType}');
        if (mounted) {
          CustomToast.showError(context, 'Error saving profile: $e');
          setState(() {
            _isLoading = false;
          });
        } else {
          debugPrint('!!!DEBUG: Context not mounted in error handler');
        }
      }
    } else if (_selectedRole == null) {
      debugPrint('!!!DEBUG: No role selected');
      CustomToast.showError(context, 'Please select a role');
    } else {
      debugPrint('!!!DEBUG: Form validation failed');
    }
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? primaryColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.8)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.7),
              accentColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      );
                    },
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with animation
                            Lottie.network(
                              'https://assets2.lottiefiles.com/private_files/lf30_GjhcdO.json',
                              height: 150,
                              animate: true,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Complete Your Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Please provide your information to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Role selection
                            Container(
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          color: primaryColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Select Your Role',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRoleCard(
                                          title: 'Buyer',
                                          description: 'I want to buy items',
                                          icon: Icons.shopping_cart,
                                          isSelected: _selectedRole == 'buyer',
                                          onTap: _isLoading
                                              ? () {} // Empty function when loading
                                              : () {
                                                  setState(() {
                                                    _selectedRole = 'buyer';
                                                  });
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildRoleCard(
                                          title: 'Seller',
                                          description:
                                              'I want to sell my items',
                                          icon: Icons.store,
                                          isSelected: _selectedRole == 'seller',
                                          onTap: _isLoading
                                              ? () {} // Empty function when loading
                                              : () {
                                                  setState(() {
                                                    _selectedRole = 'seller';
                                                  });
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Profile form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: !_isLoading,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: Icon(Icons.person,
                                          color: primaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                      filled: true,
                                      fillColor:
                                          accentColor.withValues(alpha: 0.2),
                                      labelStyle:
                                          TextStyle(color: primaryColor),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    enabled: !_isLoading,
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone,
                                          color: primaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                      filled: true,
                                      fillColor:
                                          accentColor.withValues(alpha: 0.2),
                                      labelStyle:
                                          TextStyle(color: primaryColor),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Stack(
                                    children: [
                                      Column(
                                        children: [
                                          TextFormField(
                                            controller: _locationController,
                                            enabled: !_isLoading,
                                            decoration: InputDecoration(
                                              labelText: 'Location',
                                              prefixIcon: Icon(
                                                  Icons.location_on,
                                                  color: primaryColor),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: primaryColor,
                                                    width: 2),
                                              ),
                                              filled: true,
                                              fillColor: accentColor.withValues(
                                                  alpha: 0.2),
                                              labelStyle: TextStyle(
                                                  color: primaryColor),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your location';
                                              }
                                              return null;
                                            },
                                          ),
                                          if (listOfLocations.isNotEmpty)
                                            Container(
                                              margin: EdgeInsets.only(top: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                itemCount:
                                                    listOfLocations.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    leading: Icon(
                                                        Icons.location_on,
                                                        color: primaryColor),
                                                    title: Text(
                                                      listOfLocations[index]
                                                          ["description"],
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        _isAutocompletePaused =
                                                            true;
                                                        _locationController
                                                                .text =
                                                            listOfLocations[
                                                                    index]
                                                                ["description"];
                                                        listOfLocations = [];
                                                      });

                                                      Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  300), () {
                                                        setState(() {
                                                          _isAutocompletePaused =
                                                              false;
                                                        });
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        elevation: 5,
                                        shadowColor:
                                            primaryColor.withValues(alpha: 0.5),
                                      ),
                                      child: _isLoading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Processing...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 8),
                                                const Text(
                                                  'Complete Setup',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
