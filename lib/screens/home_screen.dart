import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// ✅ IMPORTS
import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Default starting point (Islamabad)
  LatLng _currentLocation = const LatLng(33.6844, 73.0479);
  final MapController _mapController = MapController();

  // Repository Instance
  final ActivityRepository _repository = ActivityRepository();

  bool _isLoading = true;
  // Note: _isUploading is not needed for instant save logic

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // --- LOCATION LOGIC ---
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    // 2. Check Permissions
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
        // ---------------------------------------------------------
        // 👇 OPTION 1: REAL GPS (Use this for final submission)
        _currentLocation = LatLng(position.latitude, position.longitude);

        // 👇 OPTION 2: FAKE LOCATION (Uncomment to test "moving" on Laptop)
        // _currentLocation = const LatLng(33.7000, 73.0600);
        // ---------------------------------------------------------

        _isLoading = false;
      });

      // Move map to the new location
      _mapController.move(_currentLocation, 15.0);

    } catch (e) {
      print("Error getting location: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- CAMERA LOGIC ---
  Future<void> _openCamera() async {
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (imagePath != null && mounted) {
      _showSaveDialog(imagePath);
    }
  }

  // --- INSTANT SAVE DIALOG (No Loading) ---
  void _showSaveDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Activity?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(imagePath), height: 150, fit: BoxFit.cover),
            const SizedBox(height: 10),
            Text("Location: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () {
              // 1. Create Model Object
              final newActivity = ActivityModel(
                id: DateTime.now().toString(),
                latitude: _currentLocation.latitude,
                longitude: _currentLocation.longitude,
                imagePath: imagePath,
                timestamp: DateTime.now(),
              );

              // 2. ⚡ CLOSE DIALOG INSTANTLY (Do not wait for server)
              Navigator.pop(ctx);

              // 3. Show a quick message so user knows it worked
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Saving in background... 🚀"),
                  duration: Duration(seconds: 1), // Disappears quickly
                ),
              );

              // 4. Send to server in Background (Fire & Forget)
              _repository.uploadActivity(newActivity);
            },
            child: const Text("Save Immediately"),
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
        actions: [
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              }
          )
        ],
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // GPS Button (Refreshes Location)
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: _determinePosition,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.indigo),
          ),
          const SizedBox(height: 16),
          // Camera Button
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: _openCamera,
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }
}