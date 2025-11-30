import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyD-S4vYD6BNlCBf-ZTVYnEFQI1Wjcfgt0Y',
          appId: '1:109464088870:android:f6b55fec715446edbd8ae7',
          messagingSenderId: '1094640888870',
          projectId: 'smarttrackerassignment3-45df0',
          storageBucket: 'smarttrackerassignment3-45df0.appspot.com',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
      // ✅ WINDOWS SUPPORT ADDED HERE
      // Hum Android wali keys hi use kar rahe hain taake initialization error na aye
        return const FirebaseOptions(
          apiKey: 'AIzaSyD-S4vYD6BNlCBf-ZTVYnEFQI1Wjcfgt0Y',
          appId: '1:109464088870:android:f6b55fec715446edbd8ae7',
          messagingSenderId: '1094640888870',
          projectId: 'smarttrackerassignment3-45df0',
          storageBucket: 'smarttrackerassignment3-45df0.appspot.com',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}