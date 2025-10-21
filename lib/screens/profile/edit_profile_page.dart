import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/custom_toast.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String location;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _locationController = TextEditingController(text: widget.location);
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'displayName': _nameController.text,
          'phone': _phoneController.text,
          'location': _locationController.text,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context, {
            "name": _nameController.text,
            "email": widget.email, // Email remains unchanged
            "phone": _phoneController.text,
            "location": _locationController.text,
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        CustomToast.showError(context, 'Error saving changes');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      String address =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      return address;
    } catch (e) {
      debugPrint('Error converting coordinates to address: $e');
      return "Unknown Location";
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      CustomToast.showError(context, 'Location services are disabled. Please enable location services.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        CustomToast.showWarning(context, 'Location permissions are denied. Please enable them in the app settings.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      CustomToast.showWarning(context, 'Location permissions are permanently denied. Please enable them in the app settings.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String address = await _getAddressFromCoordinates(
          position.latitude, position.longitude);

      setState(() {
        _locationController.text = address;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      CustomToast.showError(context, 'Error getting location');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // This allows content to flow behind the AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          title: Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                CustomToast.showInfo(context, 'Profile is already in edit mode');
              },
            ),
          ],
          elevation: 0, // Remove shadow
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 8, right: 16, left: 16, bottom: 16),
            child: Column(
              children: [
                SizedBox(height: 12), // Small spacing after AppBar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple[100],
                    child:
                        Icon(Icons.person, size: 50, color: Colors.deepPurple),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField("Name", Icons.person, _nameController),
                        _buildEmailField(),
                        _buildTextField("Phone", Icons.phone, _phoneController),
                        _buildTextField(
                            "Location", Icons.location_on, _locationController),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _getCurrentLocation,
                            icon: Icon(Icons.my_location, color: Colors.white),
                            label: Text(
                              "Use Current Location",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      disabledBackgroundColor: Colors.deepPurple[200],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _emailController,
        enabled: false,
        decoration: InputDecoration(
          labelText: "Email",
          prefixIcon: Icon(Icons.email, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
