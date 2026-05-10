// Android + Web for project diabetes-prediction-43d50.
//
// Web: Firebase Console → Project settings → Your apps → Add app → Web.
// Copy `appId` from the JS snippet into [web] below if initialization fails.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Add an iOS/macOS app in Firebase Console and extend firebase_options.dart '
          '(or run flutterfire configure).',
        );
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android and Web. Use an Android emulator, '
          'Chrome (web), or extend firebase_options.dart for desktop.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeH4peDElpMtKJwjNd9fWWizb3Ey8p33M',
    appId: '1:777282256319:android:091b9cc41726fc3364b50a',
    messagingSenderId: '777282256319',
    projectId: 'diabetes-prediction-43d50',
    storageBucket: 'diabetes-prediction-43d50.firebasestorage.app',
  );

  /// Replace [appId] with the value from the Firebase Web-app snippet if login fails on web.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDeH4peDElpMtKJwjNd9fWWizb3Ey8p33M',
    appId: '1:777282256319:web:9c4e8b2a7f1d506384172963',
    messagingSenderId: '777282256319',
    projectId: 'diabetes-prediction-43d50',
    authDomain: 'diabetes-prediction-43d50.firebaseapp.com',
    storageBucket: 'diabetes-prediction-43d50.firebasestorage.app',
  );
}
