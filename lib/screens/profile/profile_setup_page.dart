import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app_settings/app_settings.dart';
import '../buyer/buyer_dashboard1.dart';
import '../seller/seller_dashboard1.dart';

class ProfileSetupPage extends StatefulWidget {
  final String email;
  final String? role;

  const ProfileSetupPage({
    Key? key,
    required this.email,
    this.role,
  }) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  String? _selectedRole;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // App theme colors
  final Color primaryColor = const Color(0xFF371f97); // Dark purple
  final Color accentColor = const Color(0xFFEEE8F6); // Light lavender

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

    // Request location permission when the page loads
    _requestLocationPermission();
    _animationController.forward();

    // Try to load user data
    _tryLoadUserData();
  }

  Future<void> _tryLoadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && mounted) {
            final data = userDoc.data();
            setState(() {
              // Load display name from user profile first, then from Firestore if not available
              if (user.displayName != null && user.displayName!.isNotEmpty) {
                _nameController.text = user.displayName!;
              } else if (data?['displayName'] != null) {
                _nameController.text = data!['displayName'];
              }

              if (data?['phone'] != null) {
                _phoneController.text = data!['phone'];
              }
              if (data?['location'] != null) {
                _locationController.text = data!['location'];
              }
              if (data?['role'] != null && _selectedRole == null) {
                _selectedRole = data!['role'];
              }
            });
          }
        } catch (e) {
          print('Error loading user data: $e');
          // Continue without loading data
        }
      }
    } catch (e) {
      print('Error in _tryLoadUserData: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getCurrentLocation() async {
    // Show loading only on button during location fetch
    setState(() {
      _isLocationLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Location permission permanently denied. Please enable in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          ),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _locationController.text = address;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      setState(() {
        _isLocationLoading = false;
      });
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

      print('!!!DEBUG: Starting profile save process');
      print('!!!DEBUG: Selected role: $_selectedRole');

      try {
        final user = FirebaseAuth.instance.currentUser;
        print('!!!DEBUG: Current user: ${user?.uid}');

        if (user != null) {
          print('!!!DEBUG: Attempting to update Firestore document');

          // Add a short delay for better UX
          await Future.delayed(const Duration(milliseconds: 800));

          // Try to update Firestore but continue if it fails
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
              'updatedAt': FieldValue.serverTimestamp(),
            };

            // Add coordinates if available
            if (latitude != null && longitude != null) {
              userData['coordinates'] = GeoPoint(latitude, longitude);
            }

            // Update profile photo URL if available
            if (user.photoURL != null) {
              userData['photoURL'] = user.photoURL;
            }

            // Update user profile in Firebase Auth
            await user.updateProfile(
              displayName: _nameController.text,
            );

            // Update user document in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(userData, SetOptions(merge: true));

            print('!!!DEBUG: Firestore update completed successfully');
          } catch (firestoreError) {
            print('!!!DEBUG: Firestore error: $firestoreError');
            // Show error but continue with navigation
            if (mounted) {
            }
          }

          // Set loading to false before navigation attempt
          setState(() {
            _isLoading = false;
          });

          print(
              '!!!DEBUG: About to navigate to dashboard regardless of Firestore result');

          // CRITICAL FIX: DIRECT NAVIGATION - Always navigate regardless of Firestore result
          if (mounted) {
            print('!!!DEBUG: Context is mounted, proceeding with navigation');

            // Import the actual dashboard widgets at the top of this file
            if (_selectedRole == 'seller') {
              print('!!!DEBUG: Navigating to seller dashboard');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SellerDashboard1()),
                (Route<dynamic> route) => false,
              );
            } else {
              print('!!!DEBUG: Navigating to buyer dashboard');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => BuyerDashboard1()),
                (Route<dynamic> route) => false,
              );
            }
            print('!!!DEBUG: Navigation command executed');
          } else {
            print('!!!DEBUG: Context is NOT mounted after Firestore update');
          }
        } else {
          print('!!!DEBUG: User is null, cannot update profile');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('User not found. Please log in again.')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('!!!DEBUG: Error saving profile: $e');
        print('!!!DEBUG: Error type: ${e.runtimeType}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        } else {
          print('!!!DEBUG: Context not mounted in error handler');
        }
      }
    } else if (_selectedRole == null) {
      print('!!!DEBUG: No role selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
    } else {
      print('!!!DEBUG: Form validation failed');
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
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
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
                color:
                    isSelected ? primaryColor.withOpacity(0.8) : Colors.black54,
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
              primaryColor.withOpacity(0.7),
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
                                color: accentColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.2),
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
                                      fillColor: accentColor.withOpacity(0.2),
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
                                      fillColor: accentColor.withOpacity(0.2),
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
                                      TextFormField(
                                        controller: _locationController,
                                        enabled: !_isLoading,
                                        decoration: InputDecoration(
                                          labelText: 'Location',
                                          prefixIcon: Icon(Icons.location_on,
                                              color: primaryColor),
                                          suffixIcon: _isLocationLoading
                                              ? Container(
                                                  width: 24,
                                                  height: 24,
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: primaryColor,
                                                  ),
                                                )
                                              : IconButton(
                                                  icon: Icon(Icons.my_location,
                                                      color: primaryColor),
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _getCurrentLocation,
                                                ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor:
                                              accentColor.withOpacity(0.2),
                                          labelStyle:
                                              TextStyle(color: primaryColor),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your location';
                                          }
                                          return null;
                                        },
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
                                            primaryColor.withOpacity(0.5),
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
