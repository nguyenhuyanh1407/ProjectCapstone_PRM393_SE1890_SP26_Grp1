import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('DefaultFirebaseOptions have not been configured for web');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for iOS');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlN-ixpaJwyh9jWFb83uMcmd1_TRL5BD0',
    appId: '1:788224320201:android:af2ece6082e64962fda318',
    messagingSenderId: '788224320201',
    projectId: 'tourbookingapp-cf9d9',
    storageBucket: 'tourbookingapp-cf9d9.firebasestorage.app',
  );
}
