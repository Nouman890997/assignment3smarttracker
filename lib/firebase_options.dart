// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          // ⚠️ 1. API KEY (Web API Key from Project Settings)
          apiKey: 'AIzaSyD-S4vYD6BNlCBf-ZTVYnEFQI1Wjcfgt0Y',

          // ⚠️ 2. APP ID (App ID from 'Your apps' section)
          appId: '1:109464088870:android:f6b55fec715446edbd8ae7',

          // ⚠️ 3. MESSAGING SENDER ID (Project Number from Project Settings)
          messagingSenderId: '1094640888870',

          // ✅ CONFIRMED VALUES (Project ID and Storage Bucket)
          projectId: 'smarttrackerassignment3-45df0',
          storageBucket: 'smarttrackerassignment3-45df0.appspot.com',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}