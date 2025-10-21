import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final double? distanceInKm;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onConfirm;

  const MapControls({
    super.key,
    required this.distanceInKm,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            distanceInKm != null
                ? 'Distance: ${distanceInKm!.toStringAsFixed(2)} km'
                : 'Calculating...',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: onZoomIn,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: onZoomOut,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onConfirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
