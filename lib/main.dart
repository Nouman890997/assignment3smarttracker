import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/activity_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter Engine ko start karna zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialize karna (Windows support ke sath)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Data Provider ko puri app mein available kar rahe hain
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
      title: 'Smart Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // App yahan se shuru hogi
      home: const HomeScreen(),
    );
  }
}