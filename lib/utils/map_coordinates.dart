/// Simple coordinate class to replace Firestore GeoPoint
class MapCoordinates {
  final double latitude;
  final double longitude;

  MapCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory MapCoordinates.fromMap(Map<String, dynamic> map) {
    return MapCoordinates(
      latitude: (map['lat'] ?? 0.0).toDouble(),
      longitude: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,
      'lng': longitude,
    };
  }
}
