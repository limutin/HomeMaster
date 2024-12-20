// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwU-XyBYiHdlh9qJzaE-ZUByme_ESs774',
    appId: '1:98981312548:web:663ea170a54166e11700b1',
    messagingSenderId: '98981312548',
    projectId: 'homemaster-60771',
    authDomain: 'homemaster-60771.firebaseapp.com',
    storageBucket: 'homemaster-60771.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNs6UXYsTRGMKDChHKcTYbyeSWj2i7sOs',
    appId: '1:98981312548:android:81c39d347b2eee5e1700b1',
    messagingSenderId: '98981312548',
    projectId: 'homemaster-60771',
    storageBucket: 'homemaster-60771.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7pLZUfmUcmgtXDDvY3wp2-IWM36CbY5Q',
    appId: '1:98981312548:ios:001f7f5c389310761700b1',
    messagingSenderId: '98981312548',
    projectId: 'homemaster-60771',
    storageBucket: 'homemaster-60771.appspot.com',
    iosBundleId: 'com.example.homemaster',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7pLZUfmUcmgtXDDvY3wp2-IWM36CbY5Q',
    appId: '1:98981312548:ios:001f7f5c389310761700b1',
    messagingSenderId: '98981312548',
    projectId: 'homemaster-60771',
    storageBucket: 'homemaster-60771.appspot.com',
    iosBundleId: 'com.example.homemaster',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCwU-XyBYiHdlh9qJzaE-ZUByme_ESs774',
    appId: '1:98981312548:web:cfe0ad4af06b11901700b1',
    messagingSenderId: '98981312548',
    projectId: 'homemaster-60771',
    authDomain: 'homemaster-60771.firebaseapp.com',
    storageBucket: 'homemaster-60771.appspot.com',
  );
}
