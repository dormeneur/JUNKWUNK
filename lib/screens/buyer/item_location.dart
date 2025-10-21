import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../services/api_keys.dart';
import 'widgets/map_controls.dart';

class ItemLocation extends StatefulWidget {
  final GeoPoint coordinates;
  const ItemLocation({super.key, required this.coordinates});

  @override
  State<ItemLocation> createState() => _ItemLocationState();
}

class _ItemLocationState extends State<ItemLocation> {
  GoogleMapController? _mapController;
  double _currentZoom = 13;

  final Color primaryColor = const Color(0xFF371F97);

  LatLng? userLocation;
  List<LatLng> polylineCoordinates = [];
  bool isLoading = true;
  double? distanceInKm;

  final String apiKey = googleApiKey;

  @override
  void initState() {
    super.initState();
    fetchUserCoordinates();
  }

  Future<void> fetchUserCoordinates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['coordinates'] != null) {
          final GeoPoint geo = doc['coordinates'];
          userLocation = LatLng(geo.latitude, geo.longitude);
          await fetchRoute();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user coordinates: $e");
    }

    setState(() => isLoading = false);
  }

  double calculateZoomLevel(double distanceKm) {
    if (distanceKm < 1) return 17;
    if (distanceKm < 5) return 15;
    if (distanceKm < 10) return 14;
    if (distanceKm < 25) return 13;
    if (distanceKm < 50) return 12;
    if (distanceKm < 100) return 11;
    if (distanceKm < 200) return 10;
    if (distanceKm < 400) return 9;
    if (distanceKm < 700) return 8;
    if (distanceKm < 1000) return 7;
    if (distanceKm < 1500) return 6;
    if (distanceKm < 2000) return 5.5;
    return 5; // For distances >= 2000 km
  }

  Future<void> fetchRoute() async {
    final LatLng dest = LatLng(
      widget.coordinates.latitude,
      widget.coordinates.longitude,
    );

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${userLocation!.latitude},${userLocation!.longitude}&destination=${dest.latitude},${dest.longitude}&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['routes'].isNotEmpty) {
      final route = data['routes'][0];
      final points =
          PolylinePoints().decodePolyline(route['overview_polyline']['points']);
      final legs = route['legs'][0];

      final double newDistance = legs['distance']['value'] / 1000.0;

      setState(() {
        polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        distanceInKm = newDistance;
        _currentZoom = calculateZoomLevel(newDistance);
      });

      if (_mapController != null && userLocation != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            userLocation!.latitude < dest.latitude
                ? userLocation!.latitude
                : dest.latitude,
            userLocation!.longitude < dest.longitude
                ? userLocation!.longitude
                : dest.longitude,
          ),
          northeast: LatLng(
            userLocation!.latitude > dest.latitude
                ? userLocation!.latitude
                : dest.latitude,
            userLocation!.longitude > dest.longitude
                ? userLocation!.longitude
                : dest.longitude,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng itemLatLng = LatLng(
      widget.coordinates.latitude,
      widget.coordinates.longitude,
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('itemLocation'),
        position: itemLatLng,
        infoWindow: const InfoWindow(title: 'Item Location'),
      ),
    };

    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: userLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Item Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: itemLatLng,
                    zoom: _currentZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: false,
                  markers: markers,
                  polylines: {
                    if (polylineCoordinates.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: polylineCoordinates,
                        color: Colors.blue,
                        width: 5,
                      ),
                  },
                ),
                if (distanceInKm != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MapControls(
                      distanceInKm: distanceInKm,
                      onZoomIn: () {
                        setState(() {
                          _currentZoom += 1;
                        });
                        _mapController?.animateCamera(
                          CameraUpdate.zoomTo(_currentZoom),
                        );
                      },
                      onZoomOut: () {
                        setState(() {
                          _currentZoom -= 1;
                        });
                        _mapController?.animateCamera(
                          CameraUpdate.zoomTo(_currentZoom),
                        );
                      },
                      onConfirm: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
