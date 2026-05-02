// File generated manually from Firebase console config files.
// DO NOT EDIT - regenerate by re-downloading config files from Firebase console.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Reconfigure your Firebase app for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0R0PQ-1vV1n56jwCjPvK75xzlESksVTY',
    appId: '1:237263599895:android:0779cd0150b5bad77c5f52',
    messagingSenderId: '237263599895',
    projectId: 'lanista-9caa4',
    storageBucket: 'lanista-9caa4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOw8vgVqXNrYC2V5JSj2bzDAflJqqEETg',
    appId: '1:237263599895:ios:ad37b62bf1991d037c5f52',
    messagingSenderId: '237263599895',
    projectId: 'lanista-9caa4',
    storageBucket: 'lanista-9caa4.firebasestorage.app',
    iosBundleId: 'com.lanista.app',
  );
}
