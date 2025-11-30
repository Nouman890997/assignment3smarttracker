import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Required for File handling
import 'package:camera/camera.dart'; // Required for Camera Controller

// IMPORTANT: Ensure firebase_options.dart is generated/pasted and imported correctly
import 'firebase_options.dart';

// -------------------------------------------------------------------
// DATA MODELS & GLOBAL STATE
// -------------------------------------------------------------------

class ActivityLog {
  final String id;
  final double latitude;
  final double longitude;
  final String imagePath;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.timestamp,
  });

  // For Local Storage (SharedPreferences)
  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'imagePath': imagePath,
    'timestamp': timestamp.toIso8601String(),
  };

  // Factory constructor for Local Storage (SharedPreferences)
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Global variable for authentication
class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  // Checks current Firebase Auth status
  AuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _isLoggedIn = true;
      } else {
        _userId = null;
        _isLoggedIn = false;
      }
      notifyListeners();
    });
  }

  void login(String userId) {
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut(); // Firebase sign out
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}


// -------------------------------------------------------------------
// STATE MANAGEMENT (Provider) - Repository Logic
// -------------------------------------------------------------------

class ActivityProvider extends ChangeNotifier {
  List<ActivityLog> _activityHistory = [];
  List<ActivityLog> _offlineCache = [];
  Position? _currentLocation;
  // IMPORTANT: REPLACE with your actual REST API base URL
  final String _apiBaseUrl = "http://your-actual-rest-api.com/api";

  List<ActivityLog> get activityHistory => _activityHistory;
  List<ActivityLog> get offlineCache => _offlineCache;
  Position? get currentLocation => _currentLocation;

  ActivityProvider() {
    _initLocationTracking();
    _loadOfflineCache();
    fetchHistoryFromApi();
  }

  // --- LOCATION TRACKING (Sensor Integration) ---
  void _initLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Geolocator.getPositionStream().listen((Position position) {
        _currentLocation = position;
        notifyListeners();
      });
    }
  }

  // --- OFFLINE CACHE LOGIC ---
  Future<void> _loadOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedList = prefs.getStringList('recent_logs') ?? [];

    _offlineCache = cachedList.map((jsonString) => ActivityLog.fromJson(json.decode(jsonString))).toList();
    notifyListeners();
  }

  Future<void> _saveOfflineCache(ActivityLog newLog) async {
    final prefs = await SharedPreferences.getInstance();

    _offlineCache.insert(0, newLog);
    if (_offlineCache.length > 5) {
      _offlineCache = _offlineCache.sublist(0, 5);
    }

    final jsonList = _offlineCache.map((log) => json.encode(log.toJson())).toList();
    await prefs.setStringList('recent_logs', jsonList);
    notifyListeners();
  }

  // --- API LOGIC (CRUD) ---
  Future<bool> syncActivity(String localImagePath) async {
    if (_currentLocation == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/activities'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('activity_image', localImagePath),
      );

      request.fields['latitude'] = _currentLocation!.latitude.toString();
      request.fields['longitude'] = _currentLocation!.longitude.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) { // 201 Created
        final responseData = json.decode(response.body);
        final newLog = ActivityLog.fromJson(responseData);

        _activityHistory.insert(0, newLog);
        await _saveOfflineCache(newLog);
        return true;
      }
      return false;
    } catch (e) {
      print('API Sync Failed: $e');
      return false;
    }
  }

  Future<void> fetchHistoryFromApi() async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/activities'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _activityHistory = data.map((item) => ActivityLog.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Fetch History Failed: $e');
    }
  }
}


// -------------------------------------------------------------------
// 1. APPLICATION ROOT & ENTRY POINT
// -------------------------------------------------------------------

void main() async {
  // 1. Initialize Flutter and Firebase (UNCOMMENTED)
  WidgetsFlutterBinding.ensureInitialized();

  // 💥 ACTION NEEDED: Ensure this initialization is active
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Start the App with Providers (Clean Architecture Setup)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          color: Colors.indigo.shade700,
        ),
      ),
      // Use Consumer to decide whether to show AuthScreen or TrackerScreen
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            // User is logged in, go directly to the Tracker screen
            return const TrackerScreen();
          }
          // User is not logged in, show the Auth screen
          return const AuthScreen();
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// SCREEN 4: AUTHENTICATION PAGE (Login/Register)
// -------------------------------------------------------------------

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Logic for Firebase Login (Step 1.2)
  void _handleAuthLogin(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update AuthState upon success
      Provider.of<AuthState>(context, listen: false).login(userCredential.user!.uid);
      // Navigation is now handled by the MyApp Consumer

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.message}')),
      );
    }
  }

  // Logic for Firebase Registration (Step 1.3)
  void _handleAuthRegister(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Success: Switch to Login Tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );
      _tabController.animateTo(0);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: ${e.message}')),
      );
    }
  }

  // Widget for the standard input field
  Widget _buildInputField(String label, IconData icon, bool obscure, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SmartTracker Access'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Login', icon: Icon(Icons.login)),
            Tab(text: 'Register', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // LOGIN VIEW
          SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField('Email', Icons.email, false, _emailController),
                _buildInputField('Password', Icons.lock, true, _passwordController),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleAuthLogin(context),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),

          // REGISTER VIEW (Simplified)
          SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField('Email', Icons.email, false, _emailController),
                _buildInputField('Password', Icons.lock, true, _passwordController),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleAuthRegister(context),
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// -------------------------------------------------------------------
// SCREEN 5: MAIN TRACKER SCREEN (Map & Controls)
// -------------------------------------------------------------------

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  String? _capturedImagePath;
  GoogleMapController? mapController;
  // Final camera controller and initialization logic added in the main structure

  @override
  void initState() {
    super.initState();
    // Re-trigger history fetch when screen loads
    Provider.of<ActivityProvider>(context, listen: false).fetchHistoryFromApi();
    // _initializeCamera(); // Uncomment and implement camera initialization
  }

  // Future<void> _initializeCamera() async {
  //   // Example of camera initialization
  //   final cameras = await availableCameras();
  //   // if (cameras.isNotEmpty) {
  //   //   // Set up camera controller
  //   // }
  // }

  // @override
  // void dispose() {
  //   // _cameraController?.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final currentPos = activityProvider.currentLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Call provider logout, which triggers navigation back to AuthScreen via Consumer
              Provider.of<AuthState>(context, listen: false).logout();
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // --- MAP DISPLAY (Step 7) ---
          Expanded(
            flex: 2,
            child: currentPos == null
                ? const Center(child: CircularProgressIndicator(value: null, semanticsLabel: 'Waiting for GPS...')) // Added label
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPos.latitude, currentPos.longitude),
                zoom: 14,
              ),
              onMapCreated: (controller) => mapController = controller,
              markers: [
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: LatLng(currentPos.latitude, currentPos.longitude),
                  infoWindow: InfoWindow(title: 'Live Location: ${currentPos.latitude.toStringAsFixed(4)}, ${currentPos.longitude.toStringAsFixed(4)}'),
                ),
              ],
              myLocationEnabled: true,
            ),
          ),

          // --- CAPTURE & LOGGING CONTROLS (Step 8 & 9) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Image Preview (if captured)
                _capturedImagePath != null
                    ? Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40))
                )
                    : const Icon(Icons.location_on, size: 50, color: Colors.blue),

                // Camera Button
                ElevatedButton.icon(
                  onPressed: () async {
                    // TODO: Implement actual camera capture logic here (requires CameraController setup)

                    // MOCK PATH - Replace with real camera capture code
                    setState(() {
                      _capturedImagePath = "/data/user/0/com.example.app/cache/temp_image.jpg"; // Mock path
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Captured (Simulated)!')));
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Image'),
                ),

                // Log Activity Button (Step 9)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (currentPos == null || _capturedImagePath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please wait for GPS and capture an image.')));
                      return;
                    }
                    bool success = await activityProvider.syncActivity(_capturedImagePath!);
                    if (success) {
                      setState(() {
                        _capturedImagePath = null; // Clear image after sync
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity Logged and Synced!')));
                    }
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Log Activity'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// SCREEN 6: HISTORY SCREEN (Search, View, Delete, Offline Cache)
// -------------------------------------------------------------------

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  bool _showOffline = false;

  @override
  void initState() {
    super.initState();
    // Load API history when screen starts
    Provider.of<ActivityProvider>(context, listen: false).fetchHistoryFromApi();
  }

  List<ActivityLog> _getFilteredLogs(ActivityProvider provider) {
    List<ActivityLog> logs = _showOffline ? provider.offlineCache : provider.activityHistory;

    if (_searchQuery.isEmpty) {
      return logs;
    }

    return logs.where((log) =>
        log.timestamp.toLocal().toString().contains(_searchQuery)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final filteredLogs = _getFilteredLogs(activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Column(
            children: [
              // Search Bar (Step 10)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Search by Timestamp',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              // Toggle Offline/Online
              SwitchListTile(
                title: Text(_showOffline ? 'Showing Offline Cache (Last 5)' : 'Showing Full History (API)'),
                value: _showOffline,
                onChanged: (bool value) {
                  setState(() {
                    _showOffline = value;
                  });
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final log = filteredLogs[index];
          return ListTile(
            leading: Icon(log.imagePath.isNotEmpty ? Icons.camera_alt : Icons.location_on),
            title: Text('Location: ${log.latitude.toStringAsFixed(4)}, ${log.longitude.toStringAsFixed(4)}'),
            subtitle: Text('Time: ${log.timestamp.toLocal().toString().split('.')[0]}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // TODO: Implement API DELETE call and list update (Step 10)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete simulated for ID: ${log.id}')));
              },
            ),
            onTap: () {
              // Detailed view of the map point
              // Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(log: log)));
            },
          );
        },
      ),
    );
  }
}