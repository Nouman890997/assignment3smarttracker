import 'dart:io'; // Image show karne ke liye
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/activity_log.dart';
import '../providers/activity_provider.dart';
import 'camera_screen.dart'; // Camera Screen import ki

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _currentLocation = const LatLng(33.6844, 73.0479);
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Function to Open Camera ---
  Future<void> _openCamera() async {
    // 1. Camera Screen kholo aur Result ka intezar karo
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    // 2. Agar tasveer khainchi gayi hai
    if (imagePath != null && mounted) {
      _showSaveDialog(imagePath);
    }
  }

  // --- NEW: Dialog to Save Activity ---
  void _showSaveDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Activity?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(imagePath), height: 150, fit: BoxFit.cover), // Show Image
            const SizedBox(height: 10),
            Text("Location: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // 3. Save to Provider (State Management)
              final newActivity = ActivityLog(
                id: DateTime.now().toString(),
                latitude: _currentLocation.latitude,
                longitude: _currentLocation.longitude,
                imagePath: imagePath,
                timestamp: DateTime.now(),
              );

              Provider.of<ActivityProvider>(context, listen: false).addActivity(newActivity);

              Navigator.pop(ctx); // Close Dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activity Logged Successfully!")));
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Tracker'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.assignment3smarttracker',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60, height: 60,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),

      // TWO BUTTONS (Location & Camera)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: _determinePosition,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.indigo),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: _openCamera, // Camera kholne ka button
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }
}